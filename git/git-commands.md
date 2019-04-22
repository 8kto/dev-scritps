# Создать чистый репозиторий
git clone --bare hello hello.git


# Давайте добавим репозиторий hello.git к нашему оригинальному репозиторию.
cd hello
git remote add shared ../hello.git


# Отправить изменения в удаленный репозиторий.
git push shared master


# Получить изменения из удалённого репозитория
git remote add shared ../hello.git
git branch --track shared master
git pull

# Удалить файл из истории
git filter-branch --tree-filter 'rm -f config.ini.distr' HEAD

# Пути удалённых репо
git remote -v
git remote show

# SSH
git remote add prod1 ssh://user@host/mnt/foo/bar/my-project.git
git push prod1 master


# Найти удалённый файл в истории
git log --all --full-history -- src/ArcelorBundle/Entity/Formats/LAB/SP/LAB05_Row.php
## Показать файл из ревизии
git show <SHA> -- src/ArcelorBundle/Entity/Formats/LAB/SP/LAB05_Row.php
## Восстановить файл
git checkout <SHA>^ -- src/ArcelorBundle/Entity/Formats/LAB/SP/LAB05_Row.php
Note the caret symbol (^), which gets the checkout prior to the one identified, because at the moment of <SHA> commit the file is deleted, we need to look at the previous commit to get the deleted file's contents
Вместо хэша коммита можно использовать пути `origin/master` etc.


# Количество коммитов
git rev-list HEAD --count

## To get a commit count for a revision (HEAD, master, a commit hash):
git rev-list --count <revision>

## To get the commit count across all branches:
git rev-list --all --count


# Мигрировать базар в гит
# https://design.canonical.com/2015/01/converting-projects-between-git-and-bazaar/
git init                                        # Initialise a new git repo
bzr fast-export --plain . | git fast-import     # Import Bazaar history into Git



# Undo a commit and redo
$ git commit -m "Something terribly misguided"              (1)
$ git reset HEAD~                                           (2)
<< edit files as necessary >>                               (3)
$ git add ...                                               (4)
$ git commit -c ORIG_HEAD                                   (5)

1 This is what you want to undo
2 This leaves your working tree (the state of your files on disk) unchanged but undoes the commit and leaves the changes you committed unstaged (so they'll appear as "Changes not staged for commit" in git status and you'll need to add them again before committing). If you only want to add more changes to the previous commit, or change the commit message1, you could use git reset --soft HEAD~ instead, which is like git reset HEAD~ but leaves your existing changes staged.
3 Make corrections to working tree files.
4 git add anything that you want to include in your new commit.
5 Commit the changes, reusing the old commit message. reset copied the old head to .git/ORIG_HEAD; commit with -c ORIG_HEAD will open an editor, which initially contains the log message from the old commit and allows you to edit it. If you do not need to edit the message, you could use the -C option.


# Найти удалённый файл в истории
Последний коммит, который затрагивал данный файл
git rev-list -n 1 HEAD -- src/ArcelorBundle/Entity/Formats/LAB/SP/LAB02_Row.php

Чекаут коммита перед тем, в котором файл был удалён
git checkout <deleting_commit>^ -- <file_path>


# Удалить файл из коммита
git reset --soft HEAD^
or
git reset --soft HEAD~1

Then reset the unwanted files in order to leave them out from the commit:
git reset HEAD path/to/unwanted_file

Now commit again, you can even re-use the same commit message:
git commit -c ORIG_HEAD  


# Удалить файлы из истории
https://www.link-intersystems.com/blog/2014/07/17/remove-directories-and-files-permanently-from-git/
