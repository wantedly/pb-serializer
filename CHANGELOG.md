## Unreleased

- Support `if` option https://github.com/wantedly/pb-serializer/pull/24
- Improve error handling https://github.com/wantedly/pb-serializer/pull/26
    - raise `MissingMessageTypeError` if `message` declaration is missed
    - raise `MissingFieldError` if `attribute` declaration is missed
    - raise `InvalidOptionError` when `attribute` receives invalid params
- Introduce Pb::Serializer.configure https://github.com/wantedly/pb-serializer/pull/27
    - Add `missing_field_behavior` config to suppress `MissingFieldError`
    - Rename `InvalidOptionError` -> `InvalidAttributeOptionError`


## 0.2.1

- **BREAKING CHANGE** `required` -> `allow_nil` https://github.com/wantedly/pb-serializer/pull/21
- Make Serializer's constructors extensible https://github.com/wantedly/pb-serializer/pull/22

## 0.2.0

- **BREAKING CHANGE** https://github.com/wantedly/pb-serializer/pull/17
  - Support loading and serializing arrays
  - Bump `computed_model` from 0.1.0 to 0.2.1
  - Change API
- Add example specs https://github.com/wantedly/pb-serializer/pull/18


## 0.1.0

Initial release.
