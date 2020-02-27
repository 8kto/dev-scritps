# Git: Common cases

#### Create bare (clean) repo
``` shell script
git clone --bare hello hello.git
```

#### Add just created bare repo to the main one
``` shell script
cd hello
git remote add shared ../hello.git
```

#### Add files to the commit
Aware of commits which were pushed already: you have `push --force` it in that case (better solution is prepare another 'reverting' commit).
```shell script
git add missed file
git commit --amend
# or -n to skip git hooks
git commit -n --amend 
```

#### Remove file from the history
``` shell script
git filter-branch --tree-filter 'rm -f config.ini.distr' HEAD
``` 

#### Show remote repos info
``` shell script
git remote -v
git remote show
``` 

#### Add new remote repo by SSH
``` shell script
git remote add prod1 ssh://user@host/mnt/foo/bar/my-project.git
git push prod1 master
``` 

#### Find removed file in history
``` shell script
git log --all --full-history -- src/FileImistakenlyDeleted.json
``` 

#### Show file in commit by its hash
``` shell script
git show <SHA> -- src/MyFile.json
``` 

#### Restore file
``` shell script
git checkout <deleting_commit>^ -- src/DeletedFile.json 
# or from some specific branch
git checkout origin/master src/DeletedFile.json
```
Note the caret symbol (^), which gets the checkout prior to the one identified, 
because at the moment of <SHA> commit the file is deleted, we need to look at the previous commit to get the deleted file's contents

#### Display files in commit
``` shell script
git diff-tree --no-commit-id --name-only -r <SHA>
```

#### Show changes made by commit
```
git show <SHA>
```

#### Print commits amount
``` shell script
git rev-list HEAD --count
# To get a commit count for a revision (HEAD, master, a commit hash):
git rev-list --count <revision>
# To get the commit count across all branches:
git rev-list --all --count
``` 

#### Migrate bazaar repo into git
See https://design.canonical.com/2015/01/converting-projects-between-git-and-bazaar/
``` shell script
git init                                        # Initialise a new git repo
bzr fast-export --plain . | git fast-import     # Import Bazaar history into Git
``` 

#### Undo a commit and redo
``` shell script
git commit -m "Something terribly misguided"      (1)
git reset HEAD~                                   (2)
# edit files as necessary...                      (3)
git add ...                                       (4)
git commit -c ORIG_HEAD                           (5)
```
1. This is what you want to undo
2. This leaves your working tree (the state of your files on disk) unchanged but undoes the commit and leaves the changes you committed unstaged (so they'll appear as "Changes not staged for commit" in git status and you'll need to add them again before committing). If you only want to add more changes to the previous commit, or change the commit message1, you could use git reset --soft HEAD~ instead, which is like git reset HEAD~ but leaves your existing changes staged.
3. Make corrections to working tree files.
4. git add anything that you want to include in your new commit.
5. Commit the changes, reusing the old commit message. reset copied the old head to .git/ORIG_HEAD; commit with -c ORIG_HEAD will open an editor, which initially contains the log message from the old commit and allows you to edit it. If you do not need to edit the message, you could use the -C option.

#### Remove a file from the commit
``` shell script
git reset --soft HEAD^
# or
git reset --soft HEAD~1
```

Then reset the unwanted files in order to leave them out from the commit:
``` shell script
git reset HEAD path/to/unwanted_file
```

Now commit again, you can even re-use the same commit message:
``` shell script
git commit -c ORIG_HEAD  
```

#### Remove files from the history
For example, when you noticed there are some large bin files (e.g. images) were committed, and now `.git` is abnormal large. 
See detailed explanation here: https://www.link-intersystems.com/blog/2014/07/17/remove-directories-and-files-permanently-from-git/
