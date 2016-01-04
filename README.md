# TwitterSignIn
Because my friend tell me that UMeng ' s login with twitter cant get userInfo.And i Write this demo to help someOne who need to use twitter.

只要替换掉CJViewController中的

NSString *client_id = @"U7ne4TpV42fscArpbAqHW8Eqo";                         /**< Consumer Key (API Key)*/

NSString *secret = @"ZhZxY9TZK3sR6C6tTv4TsSBMIGNvsDlEjY72ksAQ1Mwl2CLpL4";   /**< Consumer Secret (API Secret)*/

NSString *callback = @"http://codegerms.com/callback";                      /**< Callback URL*/

替换成你申请的app相对应的字符串即可.

json-master和oauthconsumer-master不支持ARC
