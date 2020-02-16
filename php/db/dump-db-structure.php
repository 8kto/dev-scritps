#!/usr/bin/php -d memory_limit=512M
<?php
/**
 * Dump database structure: tables, views, procedures etc.
 * Prints output in STDOUT or dumps into file.
 * Validates dumps before output.
 *
 * @copyright Igor Okto <web@axisful.info>
 */

use PhpMyAdmin\SqlParser\Lexer;
use PhpMyAdmin\SqlParser\Parser;
use PhpMyAdmin\SqlParser\Utils\Error;

require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../install/Database/db.defs.php';

return new class
{
  private $outputDir = false;
  private $dbHost = 'localhost';
  private $fileNames = [];
  private $tablePrefix = '';
  private $sectionDel = '-';
  private $dbUser;
  private $dbPassword;
  private $dbName;
  private $noDestructorDump;
  private $moduleVersion;

  /**
   * @var PDO
   */
  private $db;

  /** @var array Buffer for messages */
  private $bufferOutput = [];

  /**
   * Fallbacks from the env vars
   */
  private const ENV_VARS = [
    'db-user' => 'TEST_AC_WP_DB_USER',
    'db-pass' => 'TEST_AC_WP_DB_PASS',
    'db-name' => 'TEST_AC_SRC_DB_NAME',
    'db-host' => 'TEST_AC_WP_DB_HOST',
  ];

  /**
   * Map class fields to script args
   *
   * @var array<string, string>
   */
  private const ARG_TO_FIELD = [
    'db-host' => 'dbHost',
    'db-user' => 'dbUser',
    'db-pass' => 'dbPassword',
    'db-name' => 'dbName',
    'output-dir' => 'outputDir',
    'table-prefix' => 'tablePrefix',
  ];

  /** CLI args definitions for `getopt()` */
  private const CLI_OPTIONS = [
    // Short options
    '',

    // Long options
    [
      'db-user:',
      'db-pass:',
      'db-name:',
      'db-host:',
      'table-prefix:',
      'output-dir:',
      'tables::',
      'routines::',
      'help::',
    ],
  ];

  /** @var array CLI args passed to script */
  private $scriptArguments;

  /**
   * Script documentation block
   */
  private const MSG_HELP = <<<TXT
    Dump database routines: views, procedures (TODO) etc.
    Author: Igor Okto <web@axisful.info>
    
    Usage:
       ./scripts/dump-db-structure.php [OPTIONS]
       php ./scripts/dump-db-structure.php [OPTIONS]
    
    Options will fall back to the env variables
    Add these test vars into ~/.profile
       TEST_AC_WP_DB_HOST=localhost
       TEST_AC_WP_DB_USER=root
       TEST_AC_WP_DB_PASS=preved
       TEST_AC_TARGET_DB_NAME=wordpress_test
       TEST_AC_SRC_DB_NAME=alpinewp
    
    Options (if arg is omitted then env var used):
       --db-user            Database user
       --db-pass            Database password
       --db-host            Database hostname [localhost]
       --db-name            Database name
       --output-dir         Save output in this dir. If not set, output in STDOUT.
       --table-prefix       Tables prefix in database
       --tables             Dump tables
       --routines           Dump functions and views
       --help               This help message

TXT;

  /**
   * Constructor
   *
   * @throws Exception
   */
  public function __construct()
  {
    mb_internal_encoding('UTF-8');

    // Get script options
    $this->scriptArguments = getopt(...self::CLI_OPTIONS);

    if ($this->issetArgument('help')) {
      print self::MSG_HELP;
      $this->noDestructorDump = true;
      exit(0);
    }

    $this->hydrateArguments();
    $this->validateArguments();
    $this->moduleVersion = $this->getModuleVersion();
    $this->connect();

    // Run dumping
    if ($this->issetArgument('tables')) {
      $this->fileNames[] = 'tables';
      $this->bufferOutput[] = $this->getSectionDelimiter('TABLES');
      $this->bufferOutput = array_merge($this->bufferOutput, $this->getTables());
    }
    if ($this->issetArgument('routines')) {
      $this->fileNames[] = 'routines';
      $this->bufferOutput[] = $this->getSectionDelimiter('CALLABLES');
      $this->bufferOutput = array_merge($this->bufferOutput, $this->getCallables());
      $this->bufferOutput[] = $this->getSectionDelimiter('VIEWS');
      $this->bufferOutput = array_merge($this->bufferOutput, $this->getViews());
    }
  }

  /**
   * Flush buffer on destruct
   */
  public function __destruct()
  {
    if ($this->noDestructorDump) {
      exit(0);
    }

    if (!count($this->bufferOutput)) {
      print 'No data dumped' . PHP_EOL;
      exit(1);
    }

    $sql = implode('', $this->bufferOutput);
    $date = (new DateTime())->format('Y-m-d H:i:s');

    $sql = <<<TXT
-- Alpinecamp database structure dump
-- Version: {$this->moduleVersion}
-- Table prefix: {$this->tablePrefix}
-- Created at {$date}\n
$sql
TXT;

    if (($errors = $this->validateDump($sql)) === null) {
      if ($this->outputDir) {
        $filePath = $this->compileFilename();
        file_put_contents($filePath, $sql);
        print "Output saved to [{$filePath}]" . PHP_EOL;
      } else {
        print $sql . PHP_EOL;
      }

      exit(0);
    }

    print $errors . PHP_EOL;
  }

  /**
   * Connect to DB with passed arguments
   */
  private function connect(): void
  {
    try {
      $this->db = new PDO(
        "mysql:host={$this->dbHost};dbname={$this->dbName};charset=utf8",
        $this->dbUser,
        $this->dbPassword
      );
    } catch (PDOException $e) {
      print 'Connection failed: ' . $e->getMessage();
      exit(1);
    }
  }

  /**
   * @return array
   */
  private function getTables(): array
  {
    $buffer = [];

    foreach (TABLE_DEFS as $name => $desc) {
      $statement = $this->db->query(
        "SHOW CREATE TABLE `{$this->tablePrefix}{$name}`"
      );

      if (!$statement) {
        $this->exitWithDbError($this->db->errorInfo());
      }

      $code = $statement->fetch(PDO::FETCH_NUM)[1];
      $code = $this->processCreateTableBody($code);
      $buffer[] = $this->templateTableCreateBlock($name, $desc, $code);
    }

    return $buffer;
  }

  /**
   * Build an array with CREATE statements for FUNCTIONS
   *
   * @return array
   */
  private function getCallables(): array
  {
    $buffer = [];
    $statement = $this->db->query(
      "SELECT 
          name,
          CAST(param_list AS CHAR) params,
          CAST(body_utf8 AS CHAR) code,
          CAST(returns AS CHAR) returns
      FROM
          mysql.proc
      WHERE
          db='{$this->dbName}'"
    );

    if (!$statement) {
      $this->exitWithDbError($this->db->errorInfo());
    }

    while ($row = $statement->fetch(PDO::FETCH_ASSOC)) {
      $name = $row['name'];
      $params = $row['params'];
      $code = $row['code'];
      $returns = $row['returns'];

      if ($returns) {
        $buffer[] = $this->templateFunctionCreateBlock($name, $params, $code, $returns);
      } else {
        $buffer[] = $this->templateProcedureCreateBlock($name, $params, $code);
      }
    }

    return $buffer;
  }

  /**
   * Build an array with CREATE statements for VIEWs
   *
   * @return string[]
   */
  private function getViews(): array
  {
    $buffer = [];
    $statement = $this->db->query(
      "SELECT TABLE_NAME name, VIEW_DEFINITION code
       FROM INFORMATION_SCHEMA.VIEWS
       WHERE TABLE_SCHEMA='{$this->dbName}'"
    );

    if (!$statement) {
      $this->exitWithDbError($this->db->errorInfo());
    }

    while ($row = $statement->fetch(PDO::FETCH_ASSOC)) {
      $name = $row['name'];
      $code = $row['code'];

      $buffer[] = $this->templateViewCreateBlock($name, $code);
    }

    return $buffer;
  }

  /**
   * @param string $tableName
   * @param string $desc
   * @param string $code
   *
   * @return string
   */
  private function templateTableCreateBlock(string $tableName, string $desc, string $code): string
  {
    $clearName = $this->getClearName($tableName);
    $desc = $this->commentStrings($desc);

    return <<<SQL
\n-- Table `{$clearName}`
{$desc}
{$code};\n\n
SQL;
  }

  /**
   * @param string $funcName
   * @param string $params
   * @param string $code
   * @param string $returns
   *
   * @return string
   */
  private function templateFunctionCreateBlock(
    string $funcName,
    string $params,
    string $code,
    string $returns
  ): string {
    $params = $this->process_mysql_output($params);
    $code = $this->process_mysql_output($code);
    $returns = $this->process_mysql_output($returns);

    $clearName = $this->getClearName($funcName);
    $desc = CALLABLE_DEFS[$clearName] ?? '';
    if (!$desc) {
      $desc = '[No definition found for function]';
    }
    $desc = $this->commentStrings($desc);

    return <<<SQL
\n-- Function `{$funcName}`
{$desc}
DELIMITER $$
DROP FUNCTION IF EXISTS `{$funcName}`$$
CREATE FUNCTION `{$funcName}`(
  ${params}
)
  RETURNS {$returns}
  {$code}$$
DELIMITER ;\n\n
SQL;
  }

  /**
   * @param string $funcName
   * @param string $params
   * @param string $code
   *
   * @return string
   */
  private function templateProcedureCreateBlock(
    string $funcName,
    string $params,
    string $code
  ): string {
    // Fix internal MySQL formatting
    $code = $this->process_mysql_output($code);
    $params = $this->process_mysql_output($params);

    $clearName = $this->getClearName($funcName);
    $desc = CALLABLE_DEFS[$clearName] ?? '';
    if (!$desc) {
      $desc = '[No definition found for function]';
    }
    $desc = $this->commentStrings($desc);

    return <<<SQL
\n-- Procedure `{$funcName}`
{$desc}
DELIMITER $$
DROP PROCEDURE IF EXISTS `{$funcName}`$$
CREATE PROCEDURE `{$funcName}`(
  ${params}
)
  {$code}$$
DELIMITER ;\n\n
SQL;
  }

  /**
   * Fix internal MySQL formatting
   *
   * @param string $output
   *
   * @return string
   */
  private function process_mysql_output(string $output): string
  {
    return preg_replace('/\r/', '', $output);
  }

  /**
   * @param string $viewName
   * @param string $code
   *
   * @return string
   */
  private function templateViewCreateBlock(string $viewName, string $code): string
  {
    $clearName = $this->getClearName($viewName);
    $code = $this->clearCodeFromDbName($code);
    $code = SqlFormatter::format($code, false);

    $desc = VIEW_DEFS[$clearName] ?? '';
    if (!$desc) {
      $desc = '[No definition found for view]';
    }
    $desc = $this->commentStrings($desc);

    return <<<SQL
\n-- View `{$viewName}`
{$desc}
CREATE OR REPLACE VIEW {$viewName} AS
  {$code};\n\n
SQL;
  }

  /**
   * @param string $code
   *
   * @return string
   */
  private function processCreateTableBody(string $code): string
  {
    $this->clearCodeFromDbName($code);

    // Removes autoincreament value at the table definition
    return preg_replace('/AUTO_INCREMENT=\d+\s*/m', ' ', $code);
  }

  /**
   * Remove dbname preceding table names
   *
   * @param string $code
   *
   * @return string
   */
  private function clearCodeFromDbName(string $code): string
  {
    return preg_replace("/[`'\"]?{$this->dbName}[`'\"]?\./mi", '', $code);
  }

  /**
   * Precede each string with SQL comment
   *
   * @param string $strings
   * @param string $commentType
   *
   * @return string
   */
  private function commentStrings(string $strings, string $commentType = '-- '): string
  {
    return preg_replace('/^\s*/m', $commentType, $strings);
  }

  /**
   * Get clear name wo table prefix
   *
   * @param string $name
   *
   * @return string
   */
  private function getClearName(string $name): string
  {
    return preg_replace("/^{$this->tablePrefix}/", '', $name);
  }

  /**
   * @param string $code
   *
   * @return string|null
   */
  private function validateDump(string $code): ?string
  {
    $lexer = new Lexer($code, false);
    $parser = new Parser($lexer->list);
    $errors = Error::get([$lexer, $parser]);

    if (count($errors) === 0) {
      return null;
    }

    $output = Error::format($errors);

    return implode(PHP_EOL, $output) . PHP_EOL;
  }

  /**
   * @return string
   */
  private function getModuleVersion(): string
  {
    $moduleCode = file_get_contents(__DIR__ . '/../alpinecamp.php');
    preg_match('/Version:\s*([0-9.]+).*$/im', $moduleCode, $matches);

    if (!isset($matches[1])) {
      print 'Cannot parse module version' . PHP_EOL;
      exit(1);
    }

    return $matches[1];
  }

  /**
   * @return string
   */
  private function compileFilename(): string
  {
    $fileName = implode('-', $this->fileNames);

    return "{$this->outputDir}/{$fileName}-v{$this->moduleVersion}.sql";
  }

  /**
   * Set class fields to args or env fallbacks
   */
  private function hydrateArguments(): void
  {
    [, $longArgs] = self::CLI_OPTIONS;

    /** @var string $argument */
    foreach ($longArgs as $argument) {
      $argument = rtrim($argument, ':');
      $field = $this->getFieldForArgument($argument);

      if (!$field) {
        continue;
      }

      $value = $this->getArgumentValue($argument);

      if (!$value) {
        if (array_key_exists($argument, self::ENV_VARS)) {
          // Get prop from env
          $value = getenv(self::ENV_VARS[$argument]);
        } else {
          // Field should have a default value
          $value = $this->$field;
        }
      }

      $this->$field = $value;
    }
  }

  /**
   * Validates hydrated props of class instance
   */
  private function validateArguments(): void
  {
    /** @var string $field */
    foreach (self::ARG_TO_FIELD as $arg => $field) {
      if ($this->$field === null) {
        throw new InvalidArgumentException("No value provided for {$arg} argument");
      }
    }

    $this->dbName = filter_var($this->dbName, FILTER_SANITIZE_STRING);
  }

  /**
   * Is argument set for script
   *
   * @param string $arg
   *
   * @return bool
   */
  private function issetArgument(string $arg): bool
  {
    return array_key_exists($arg, $this->scriptArguments);
  }

  /**
   * @param string      $argument
   * @param string|null $default
   *
   * @return mixed|string|null
   */
  private function getArgumentValue(string $argument, ?string $default = null)
  {
    if ($this->issetArgument($argument)) {
      return $this->scriptArguments[$argument];
    }

    return $default;
  }

  /**
   * @param string $argument
   *
   * @return string|null
   */
  private function getFieldForArgument(string $argument): ?string
  {
    if (array_key_exists($argument, self::ARG_TO_FIELD)) {
      return self::ARG_TO_FIELD[$argument];
    }

    return null;
  }

  /**
   * Get a line which will be used a section delimiter
   *
   * @param string $title
   *
   * @return string
   */
  private function getSectionDelimiter(string $title): string
  {
    $titleLine = "-- {$title}";
    $bottomLine = str_repeat($this->sectionDel, 87);
    $bottomLine = "-- {$bottomLine}";

    return PHP_EOL
           . implode(PHP_EOL, [$titleLine, $bottomLine,])
           . PHP_EOL;
  }

  /**
   * @param array $errorInfo
   */
  private function exitWithDbError(array $errorInfo): void
  {
    /** @noinspection ForgottenDebugOutputInspection */
    print_r($errorInfo);
    exit(1);
  }
};
