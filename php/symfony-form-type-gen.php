#!/usr/bin/env php
<?php

/**
 * Generate form type layout for Symfony entity
 *
 * @author Igor Ivlev igor@loftdigital.com
 *
 * Usage:
 *   Get documentation:
 *     ./scripts/symfony-form-type-gen.php --help
 *
 *   Get buildForm method for form type:
 *     ./scripts/symfony-form-type-gen.php --build-form-method --entity src/Entity/Proposal/ProposalMeetingRoom.php
 *
 *   Get AJAX payload for Postman calls:
 *     ./scripts/symfony-form-type-gen.php --print-json-payload --entity src/Entity/Proposal/ProposalMeetingRoom.php
 *
 *   Get valid data method body for use in controller test:
 *     ./scripts/symfony-form-type-gen.php --print-test-valid-data-method --entity src/Entity/Proposal/ProposalMeetingRoom.php
 */
return new class
{
    private $classPath;
    private $className;
    private $reflect;

    /** CLI args definitions for `getopt()` */
    private const CLI_OPTIONS = [
        // Short options
        'b::j::t::h::',

        // Long options
        [
            'entity:',
            'build-form-method::',
            'print-json-payload::',
            'print-test-valid-data-method::',
            'help::'
        ],
    ];

    /** @var array CLI args passed to script */
    private $scriptOptions;

    /** @var array Fields to skip from entity */
    private const SKIP_FIELDS = ['id', 'created_at', 'updated_at'];

    // Field types
    private const FIELD_SIMPLE_TYPE = 0;
    private const FIELD_DATE_TYPE = 1;
    private const FIELD_OM_TYPE = 2;
    private const FIELD_MO_TYPE = 3;
    private const FIELD_MM_TYPE = 4;
    private const FIELD_OO_TYPE = 5;

    /** @var array[] Buffer for misc types of fields */
    private $fieldsBuffer = [
        self::FIELD_SIMPLE_TYPE => [],
        self::FIELD_DATE_TYPE => [],
        self::FIELD_OM_TYPE => [],
        self::FIELD_MO_TYPE => [],
        self::FIELD_MM_TYPE => [],
        self::FIELD_OO_TYPE => [],
    ];

    /** @var array Map field type to template vars */
    private $fieldsMap = [
        self::FIELD_SIMPLE_TYPE => '{SimpleFields}',
        self::FIELD_DATE_TYPE => '{Dates}',
        self::FIELD_OM_TYPE => '{OneToMany}',
        self::FIELD_MO_TYPE => '{ManyToOne}',
        self::FIELD_MM_TYPE => '{ManyToMany}',
        self::FIELD_OO_TYPE => '{OneToOne}',
    ];

    /** @var array Buffer for messages */
    private $bufferOutput = [];

    /**
     * List of fields that could be printed as JSON
     * suitable for remote calls with payload
     *
     * @var array[] Each item is [snaked_field_name, varType[]]
     */
    private $jsonFields = [];

    /**
     * @var array List of processed fields, used to validate result
     */
    private $processedFields = [];

    private const MSG_HELP = <<<TXT
    Simple form type layout generator for Symfony's entities
    Usage:
        php symfony-form-type-gen.php [command] [options]
    
    Commands:      
        -h|--help                 This documentation block
        -b|--build-form-method    Generate layout for buildForm method of FormTypeInterface
        -j|--print-json-payload   Print JSON with fields suitable for remote calls as a payload
        -t|--print-valid-dataset  Generate dataset for getValidData method of controller tests
    
    Options:
        --entity  Path to the entity that shall be parsed 
    
TXT;

    /**
     * Template for the whole `buildForm` method
     */
    private const TPL_BUILD_FORM = <<<'TPL'
public function buildForm(FormBuilderInterface $builder, array $options): void
{
    $builder
        ->add('id', null, ['mapped' => false])
        ->add('created_at', null, ['mapped' => false])
        ->add('updated_at', null, ['mapped' => false])
        {SimpleFields};
    {Dates}
    {OneToMany}
    {ManyToOne}
}
TPL;

    /**
     * Template for simple form field
     */
    private const TPL_FIELD_SIMPLE = <<<'TPL'
        ->add('%s', null, [
            'required' => %s,
            'label' => '%s',
        ])
TPL;

    /**
     * Template for date fields
     */
    private const TPL_FIELD_DATE = <<<'TPL'
        $builder
            ->add('%s', null, [
                'required' => %s,
                'label' => '%s',
            ])
            ->get('%s')->addModelTransformer(
                self::getDateTimeTransformer()
            );
TPL;

    /**
     * Template for ManyToOne
     */
    private const TPL_FIELD_MO = <<<'TPL'
        $builder
            ->add('%s', null, [
                'required' => %s,
                'label' => '%s',
            ])
            ->get('%s')->addModelTransformer(
                new %s($options['entity_manager']) /* checkme! */
            );
TPL;

    /**
     * Template for OneToMany
     */
    private const TPL_FIELD_OM = <<<'TPL'
        $builder->add('%s', null, ['mapped' => false]);
TPL;

    /**
     * Constructor
     *
     * @throws Exception
     */
    public function __construct()
    {
        // Get script options
        [$short, $long] = self::CLI_OPTIONS;
        $this->scriptOptions = getopt($short, $long);

        if (
            $this->isOptionPresent('help', 'h') ||
            !$this->isOptionPresent('e', 'entity')
        ) {
            print self::MSG_HELP;
            exit(0);
        }

        // Required option
        $this->classPath = $this->getScriptOption('entity', 'e');

        // Extract class name from path
        preg_match('@\/(\w+)\.php$@', $this->classPath, $matches);
        $this->className = $matches[1];

        // Parse reflection class
        $this->reflect = $this->getRefClass();
        $this->parseFields();

        if ($this->isOptionPresent('b', 'build-form-method')) {
            $this->printInfo('Build form method', true);
            $this->printFormTypeDefitions();
        }

        if ($this->isOptionPresent('print-json-payload', 'j')) {
            $this->printInfo('JSON Payload', true);
            $this->printJsonPayload();
        }

        if ($this->isOptionPresent('print-test-valid-data-method', 't')) {
            $this->printInfo('Valid data set', true);
            $this->printValidDataTestMethod();
        }
    }

    /**
     * Flush buffer on destruct
     */
    public function __destruct()
    {
        foreach ($this->reflect->getProperties() as $item) {
            $name = $item->getName();

            if (
                !in_array($name, $this->processedFields, true) &&
                !in_array($name, self::SKIP_FIELDS, true)
            ) {
                $this->printWarn("Field not processed: {$name}");
            }
        }

        print implode(PHP_EOL, $this->bufferOutput);
        print PHP_EOL;
    }

    /**
     * Open file with original class,
     * clear it from dependencies, prepare to reflection
     *
     * @return ReflectionClass
     */
    private function getRefClass(): ReflectionClass
    {
        try {
            $file = file_get_contents($this->classPath);

            // Remove use statements and traits imports
            $replaced = preg_replace('@^(<\?php)[\s\S]+?(\/\*\*)@', "$1\n$2", $file);
            $replaced = preg_replace('@use\s+[^;]+;@', '', $replaced);

            // Create temp file where cleared class will be stored
            $tmpClass = "/tmp/{$this->className}.php";
            file_put_contents($tmpClass, $replaced);

            /** @noinspection PhpIncludeInspection */
            require_once $tmpClass;

            if (!class_exists($this->className)) {
                throw new RuntimeException("Cleared class not loaded: {$this->className}");
            }

            return new ReflectionClass($this->className);

        } catch (Exception $exception) {
            exit($exception->getMessage());
        }
    }

    /**
     * Parse each entity field
     */
    private function parseFields(): void
    {
        foreach ($this->reflect->getProperties() as $item) {
            $name = $item->getName();
            if (in_array($name, self::SKIP_FIELDS, true)) {
                continue;
            }

            $docblock = $item->getDocComment();
            $defType = $this->getFieldType($name, $docblock);
            $varType = $this->getVarType($name, $docblock);
            $isRequired = $this->isRequired($name, $docblock);
            $storage = &$this->fieldsBuffer[$defType];

            switch ($defType) {
                case self::FIELD_SIMPLE_TYPE:
                    $storage[] = $this->processSimpleField($name, $varType, $isRequired);
                    break;
                case self::FIELD_DATE_TYPE:
                    $storage[] = $this->processDateField($name, $varType, $isRequired);
                    break;
                case self::FIELD_MO_TYPE:
                    $storage[] = $this->processManyToOneField($name, $varType, $isRequired);
                    break;
                case self::FIELD_OM_TYPE:
                    $storage[] = $this->processOneToManyField($name);
                    break;
            }
        }

        unset($storage);
    }

    /**
     * Print out grouped form type definitions
     */
    private function printFormTypeDefitions(): void
    {
        $out = self::TPL_BUILD_FORM;
        foreach ($this->fieldsBuffer as $type => $buffer) {
            if (!empty($buffer)) {
                $placeholder = PHP_EOL;
                $placeholder .= sprintf('// %s', trim($this->fieldsMap[$type], '{}'));
                $placeholder .= PHP_EOL;
                $placeholder .= implode(PHP_EOL, $buffer);
            } else {
                $placeholder = '';
            }

            $out = str_replace($this->fieldsMap[$type], $placeholder, $out);
        }

        print "\e[45m$out\e[0m\n";
    }

    /**
     * Extract field type from comment block
     *
     * @param string $name
     * @param string $docblock
     * @return int
     */
    private function getFieldType(string $name, string $docblock): int
    {
        if (strpos($docblock, '@ORM\ManyToOne') !== false) {
            return self::FIELD_MO_TYPE;
        }
        if (strpos($docblock, '@ORM\OneToMany') !== false) {
            return self::FIELD_OM_TYPE;
        }
        if (strpos($docblock, '@ORM\OneToOne') !== false) {
            return self::FIELD_OO_TYPE;
        }
        if (strpos($docblock, '@ORM\ManyToMany') !== false) {
            return self::FIELD_MM_TYPE;
        }

        if (strpos($docblock, '@ORM\Column') !== false) {
            if ($this->isDateType($this->getVarType($name, $docblock))) {
                return self::FIELD_DATE_TYPE;
            }

            return self::FIELD_SIMPLE_TYPE;
        }

        throw new InvalidArgumentException("Cannot get field type for {$name}");
    }

    /**
     * Get `is required` status from docblock
     *
     * @param string $name
     * @param string $docblock
     * @return bool
     */
    private function isRequired(string $name, string $docblock): bool
    {
        preg_match('@nullable\s*=\s*(true|false)@m', $docblock, $matches);

        if (isset($matches[1])) {
            return $matches[1] === 'false';
        }

        $this->printWarn("<required> docblock not found for {$name}");

        return false;
    }

    /**
     * Get field type from docblock
     *
     * @param string $name
     * @param string $docblock
     * @return array
     */
    private function getVarType(string $name, string $docblock): array
    {
        preg_match('@var\s*([\w\|\[\]]+)$@m', $docblock, $matches);

        if (isset($matches[1])) {
            return explode('|', $matches[1]);
        }

        $this->printWarn('Docblock <@var> for var type not found for ' . $name);

        return [];
    }

    /**
     * Is type related to date-based types
     *
     * @param array $type
     * @return bool
     */
    private function isDateType(array $type): bool
    {
        foreach ($type as $def) {
            if (strpos($def, 'Date') !== false) {
                return true;
            }
        }

        return false;
    }

    /**
     * Get layout for simple field
     *
     * @param string $name
     * @param array $varType
     * @param bool $isRequired
     * @return string
     */
    private function processSimpleField(string $name, array $varType, bool $isRequired): string
    {
        $snaked = $this->camelToSnakeCase($name);
        $this->jsonFields[] = [$snaked, $varType];
        $this->processedFields[] = $name;

        return sprintf(
            self::TPL_FIELD_SIMPLE,
            $snaked,
            $isRequired ? 'true' : 'false',
            $this->getLabel($name)
        );
    }

    /**
     * Get layout for dates
     *
     * @param string $name
     * @param array $varType
     * @param bool $isRequired
     * @return string
     */
    private function processDateField(string $name, array $varType, bool $isRequired): string
    {
        $snaked = $this->camelToSnakeCase($name);
        $this->jsonFields[] = [$snaked, $varType];
        $this->processedFields[] = $name;

        return sprintf(
            self::TPL_FIELD_DATE,
            $snaked,
            $isRequired ? 'true' : 'false',
            $this->getLabel($name),
            $snaked
        );
    }

    /**
     * Get layout for MO
     *
     * @param string $name
     * @param array $varType
     * @param bool $isRequired
     * @return string
     */
    private function processManyToOneField(
        string $name,
        array $varType,
        bool $isRequired
    ): string {
        $snaked = $this->camelToSnakeCase($name);
        $linkedEntity = $varType[0];
        $guessedIdProcessor = sprintf('IdTo%s', $linkedEntity);
        $this->jsonFields[] = [$snaked, $varType];
        $this->processedFields[] = $name;

        return sprintf(
            self::TPL_FIELD_MO,
            $snaked,
            $isRequired ? 'true' : 'false',
            $this->getLabel($name),
            $snaked,
            $guessedIdProcessor
        );
    }

    /**
     * Get layout for OM
     *
     * @param string $name
     * @return string
     */
    private function processOneToManyField(string $name): string
    {
        $this->processedFields[] = $name;

        return sprintf(self::TPL_FIELD_OM, $this->camelToSnakeCase($name));
    }

    /**
     * List of fields that could be printed as JSON
     * suitable for remote calls with payload
     *
     * @throws Exception
     */
    private function printJsonPayload(): void
    {
        $out = [];
        foreach ($this->jsonFields as [$name, $def]) {
            $out[] = sprintf(
                "\t\"%s\": %s",
                $name,
                $this->guessPayloadValue($name, $def)
            );
        }

        printf("\e[45m \n{\n%s\n}\n \e[0m\n", implode(',' . PHP_EOL, $out));
    }

    /**
     * Method with valid test data, used in controller methods
     *
     * @throws Exception
     */
    private function printValidDataTestMethod(): void
    {
        $out = [];
        foreach ($this->jsonFields as [$name, $def]) {
            $out[] = sprintf(
                "\t'%s' => %s",
                $name,
                $this->guessPayloadValue($name, $def)
            );
        }

        printf("\e[45mreturn [\n%s\n];\n \e[0m\n", implode(',' . PHP_EOL, $out));
    }

    /**
     * Guess possible value for field by its type
     *
     * @param string $name
     * @param array $varType
     * @return mixed
     * @throws Exception
     */
    private function guessPayloadValue(string $name, array $varType)
    {
        foreach ($varType as $type) {
            switch ($type) {
                case 'string':
                    return ['"Test"', '"Name"', '"String"'][random_int(0, 2)];
                case 'int':
                    return 1;
                case 'float':
                    return random_int(100, 2000) / 100;
                case 'bool':
                    return random_int(0, 1) ? '"true"' : '"false"';
                case 'DateTime':
                    return sprintf("\"2018-09-%'.02dT00:00:00+00:00\"", random_int(1, 28));
                case 'Date':
                    return sprintf("\"2018-09-%'.02d\"", random_int(1, 28));
            }
        }

        $this->printWarn(
            sprintf('Cannot guess value for %s <%s>, use 1', $name, implode('|', $varType))
        );

        return '1';
    }

    /**
     * Convert var name from camelCase to snake_case
     *
     * @param string $name
     * @return string
     */
    private function camelToSnakeCase(string $name): string
    {
        return strtolower(preg_replace('@([A-Z])@', '_$1', $name));
    }

    /**
     * Get label from variable name
     *
     * @param string $name
     * @return string
     */
    private function getLabel(string $name): string
    {
        return ucwords(preg_replace('@([A-Z])@', ' $1', $name));
    }

    /**
     * Print message in buffer or stout
     *
     * @param string $msg
     * @param bool $forceOutput print directly in output
     */
    private function printInfo(string $msg, bool $forceOutput = false): void
    {
        $msg = "\e[96m>>> [INFO]: {$msg}\e[0m";

        if ($forceOutput) {
            print $msg . PHP_EOL;
        } else {
            $this->bufferOutput[] = $msg;
        }
    }

    /**
     * Print warning message in buffer or stout
     *
     * @param string $msg
     * @param bool $forceOutput print directly in output
     */
    private function printWarn(string $msg, bool $forceOutput = false): void
    {
        $msg = "\e[93m>>> [WARN]: {$msg}\e[0m";

        if ($forceOutput) {
            print $msg . PHP_EOL;
        } else {
            $this->bufferOutput[] = $msg;
        }
    }

    /**
     * Is argument set for script
     *
     * @param array ...$args
     * @return bool
     */
    private function isOptionPresent(...$args): bool
    {
        foreach ($this->scriptOptions as $scriptOption => $val) {
            if (in_array($scriptOption, $args, true)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Get argument that set for script if any
     *
     * @param array ...$args
     * @return mixed
     */
    private function getScriptOption(...$args)
    {
        foreach ($args as $key) {
            if (array_key_exists($key, $this->scriptOptions)) {
                return $this->scriptOptions[$key];
            }
        }

        return null;
    }
};
