# aptrepo

Maintain an host your own apt-repo.

This tool does not run its own webserver, only creates the structure needed for an apt-repo.
No local database is maintained. All the needed files are kept in the structure, so updating can be done from any machine or pipeline.

## Usage

The command has to be executed in the root of the repository. For example `/var/www/html/deb`.

`aptrepo <command>`

### `aptrepo init <name> <suite> <description>`

* Name is the name of the repository
* Suite is for example stable or testing
* Description is a short description of the repository

### `aptrepo add <package> <suite>`

Package can either be a file or a http(s) url. The file will be copied to the repository and added to the Packages file. If another version of this package already exists it will be overwritten. Multiple parallel Versions are currently not supported, because the files cannot be marked as belinging to a certain suite in the pool.

Adding the same file to another suite is possible, but the file will be copied again (or downloaded again by wget and duplicated)

### `aptrepo release <suite>`

Generates and signs the current Release file.

This is not integrated in `aptrepo add` to allow adding multiple packages/updates and only running the release once.
