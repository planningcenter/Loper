## Loper

**Lo**cal **Per**sistent Store is a Key Value store for iOS.  It's written in Swift but fully compatable with Objective-C.

---



### Getting Started



Open the store and prepare it for writing:

```objective-c
NSError *error = nil;
if (![[LOPStore defaultStore] openAndReturnError:&error]) {
  // Super good error handling
}
```



Write a value:

```objective-c
NSString *name = @"Loper";
[[LOPStore defaultStore] setObject:name forKey:@"project_name" inScope:nil];
```



Reading a value:

```objective-c
NSString *name = [[LOPStore defaultStore] stringForKey:@"project_name" inScope:nil];
```

If the value isn't found `nil` will be returned.



#### Scopes

Scopes allow you to manage a group of keys.  E.G.

```objective-c
[[LOPStore defaultStore] setObject@"example@example.com" forKey:@"email" inScope:@"logged_in"];

// User logs out

NSError *error = nil;
if (![[LOPStore defaultStore] deleteScope:@"logged_in" error:&error]) {
  // Super good error handling
}

NSString *email = [[LOPStore defaultStore] stringForKey:@"email" inScope:@"logged_in"];
// email == nil
```

This will delete all values with the `logged_in` scope.



If `nil` is passed to scope then `[LOPStore scope]` will be used.  Keys __MUST__ be unique for a scope. So setting `foo : nil` a second time will replace the original value in the store.  But setting `foo : bar` will insert a new value into the `bar` scope and keep the default scope value intact.



#### Cleanup

Because Loper is backed by a SQLite database occasionally you'll need to run `cleanup` to repack the database file if your keys are volatile.

```objective-c
NSError *error = nil;
if (![[LOPStore defaultStore] cleanupAndReturnError:&error]) {
  // Super good error handling
}
```

This operation can be slow and should occure on a background thread.  All reads & writes to the store will be blocked until this operation is completed.
