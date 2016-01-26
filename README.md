**This module is deprecated and no longer maintained.**
A working (and much more feature-complete) Object Storage GE module can be found at [renarsvilnis/fiware-object-storage-ge](https://github.com/renarsvilnis/fiware-object-storage-ge).


# fiware-object-storage

> A NodeJS module for read/write access to the FIWARE Object Storage GE

## Installation

``` bash
  $ [sudo] npm install fiware-object-storage
```

## Usage

Include the `fiware-object-storage` module and initialize it with a configuration object:

```js
fiwareObjectStorageConfig = {
  url       : 'FIWARE_OBJECTSTORAGE_URL'  // IP of the Object Storage GE, e.g. "api2.xifi.imaginlab.fr" (FIWARE Lannion2)
  auth      : 'FIWARE_AUTH_URL'           // IP of the Auth Services, likely "cloud.lab.fi-ware.org"
  container : 'some-container'            // Whatever container you want to connect to
  user      : "FIWARE_EMAIL_ADDRESS"      // Your FIWARE account email
  password  : "FIWARE_PASSWORD"           // Your FIWARE account password.. i know.. no comment.
}

var fiwareObjectStorage = require('fiware-object-storage');


fios = fiwareObjectStorage(fiwareObjectStorageConfig);

fios.connectToObjectStorage(function(){
  // Now we are connected.
  var files = fios.getFileList() // Prints file list to the console and returns it as an array of strings

});

```

## Methods

### connectToObjectStorage(callback)
Connects to the URLs declared in the config. Then calls the `callback` function

### getFileList()
Prints and returns Array of File Names

### putFile(name, data, meta)
Uploads file into the container. `name` will be the filename inside the container, `data` must be the file data in base64 encoding. `meta` can be any additional data, will be stringified.

### getFile(name)
Downloads the file called `name` from the container and returns:

```js 
{
  meta : String
  mimetype: String
  value : base64-encoded data
}
```

## License

No warranties. It's fiware-related code.

For anything else: MIT.
