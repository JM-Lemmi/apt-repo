# aptrepo

Maintain an host your own apt-repo.

This tool does not run its own webserver, only creates the structure needed for an apt-repo.
No local database is maintained. All the needed files (except for the gpg key) are kept in the structure, so updating can be done from any machine or pipeline.

## Usage

The command has to be executed in the root of the repository. For example `/var/www/html/deb`.

`aptrepo <command>`

### `aptrepo init <name> <suite> <description>`

* Name is the name of the repository
* Suite is for example stable or testing
* Description is a short description of the repository

Will also generate a gpg key that is used for signing the repository.
If you're running from a pipeline, you should probably generate this key once and then add it to the pipeline setup externally.

The GPG Key can be exported and imported with `gpg --armor --export-secret-keys <email> > gpg.private.key` and `gpg --import gpg.private.key`.
This key should obviously not be stored in your webserver! But with the import command can be imported from Github Secrets for example.

### `aptrepo add <package> <suite>`

Package can either be a file or a http(s) url. The file will be copied to the repository and added to the Packages file. If another version of this package already exists it will be overwritten. Multiple parallel Versions are currently not supported, because the files cannot be marked as belinging to a certain suite in the pool.

Adding the same file to another suite is possible, but the file will be copied again (or downloaded again by wget and duplicated)

### `aptrepo release <suite>`

Generates and signs the current Release file.

This is not integrated in `aptrepo add` to allow adding multiple packages/updates and only running the release once.

## Usage for clients

```
echo "deb [arch=amd64] http://<webserver>/deb stable main" > /etc/apt/sources.list.d/<yourpkg>.list
curl http://<webserver>/deb/gpg.key | apt-key add -
apt update
apt install <yourpkg>
```
