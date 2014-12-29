### Chef now handles URI Schemes in a case insensitive manner

Previously, when a URI scheme contained all uppercase letters, Chef would reject the URI as invalid. In compliance with RFC3986, Chef now treats URI schemes in a case insensitive manner. This applies to all resources which accept URIs such as remote_file etc.