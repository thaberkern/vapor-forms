# VaporForms

Brings simple, dynamic and re-usable web form handling to
[Vapor](https://github.com/vapor/vapor).

This library is being used in production and should be safe, but as an early
release the API is subject to change.

Don't forget to add to your `providers` if you want to use built-in Leaf tags:

```swift
import Vapor
import VaporForms

let drop = Droplet()
try drop.addProvider(VaporForms.Provider.self)
```

## Features

Create a `Fieldset` on the fly:

```swift
let fieldset = Fieldset([
  "firstName": StringField(),
  "lastName": StringField(),
])
```

and add validation:

```swift
let fieldset = Fieldset([
  "firstName": StringField(),
  "lastName": StringField(),
  "email": StringField(String.EmailValidator()),
], requiring: ["email"])
```

You can add multiple validators, too:

```swift
let fieldset = Fieldset([
  "firstName": StringField(
    String.MinimumLengthValidator(characters: 3),
    String.MaximumLengthValidator(characters: 255),
  ),
  "lastName": StringField(
    String.MinimumLengthValidator(characters: 3),
    String.MaximumLengthValidator(characters: 255),
  ),
  "email": StringField(String.EmailValidator()),
], requiring: ["email"])
```

Validate from a `request`:

```swift
fieldset.validate(request.data)
```

or even from a simple object:

```swift
fieldset.validate([
  "firstName": "Peter",
  "lastName": "Pan",
])
```

Validation results:

```swift
switch fieldset.validate(request.data) {
case .success(let data):
  let user = User(
    firstName: data["firstName"]?.string,
    lastName: data["lastName"]?.string
  )
case .failure(let errors, let data):
  // Use the field names and failed validation messages in `errors`,
  // and the passed-in values in `data` to re-render your form.
  // If a single field fails multiple validators, you'll receive
  // an error string for each rather than just failing at the first
  // validator.
}
```

Gain strongly-typed results by wrapping the `Fieldset` in a re-usable `Form`.

```swift
struct UserForm: Form {
  let firstName: String
  let lastName: String
  let email: String
  
  static let fields = Fieldset([
    "firstName": StringField(),
    "lastName": StringField(),
    "email": StringField(String.EmailValidator()),
  ], requiring: ["firstName", "lastName", "email"])
  
  init(validated: [String: Node]) throws {
    firstName = validated["firstName"]!.string!
    lastName = validated["lastName"]!.string!
    email = validated["email"]!.string!
    // validated is guaranteed to contain valid data, but
    // this initializer throws in case you'd rather use guard let
    // in place of implicitly-unwrapped optionals
  }
}

drop.get { req in
  switch try UserForm.validating(req.data) {
  case .success(let formData):
    // Return to your view, or use the properties to save a Model instance.
    return "Hello \(formData.firstName) \(formData.lastName)"
  case .failure(let invalidForm):
    // Use the leaf tags #errorsForFormInput and #valueForFormInput on the
    // InvalidForm instance to re-render your form.
    return try drop.view.make("index", [
      "form": invalidForm,
    ])
  }
}
```

Rendering a form with validation error messages:

```html
<label>Name</label>
<input type='text' name='name' value='#valueForFormInput(form, "name")'>
#errorsForFormInput(form, "name") {
#if(self) {<ul>}
#loop(self, "errorMessage") {
  <li>#(errorMessage)</li>
}
#if(self) {</ul>}
}
```

## Documentation

See the extensive tests file for full usage while in early development.
Built-in validators are in the `Validators` directory.
Proper documentation to come.

## Known issues

So far, everything works as it says on the tin.

There are some unfortunate design aspects, though, which the author hopes to
straighten out.

One of Swift's greatest assets is strong typing, but this library largely
bypasses all those benefits. This is due to limitations in both Swift's
introspection mechanism, and the author's general intelligence. The `Form`
protocol is an attempt to resolve this lack; *in theory*, when the end-user
fills out their `fields` property and `init` method correctly there should
be no problems, but it would be nice for the compiler to catch any typos
before the app runs. Using an `enum` for field names would be a good idea.

The majority of the library uses `...ValidationResult` enums to return useful
information about the success or failure of validation. However, the `Form`
protocol also `throws` because the mapping of validated data to instance
property is implemented by the end-user and errors may arise.

Vapor's `Node` is heavily used, as is `Content`. Unfortunately, the built-in
[validation](https://vapor.github.io/documentation/guide/validation.html)
is (despite the author's best efforts) almost completely unused. Future work
may be able to converge the two validation mechanisms enough that this library
doesn't need to supply its own.
