# Test Entities for testing Slate functionality

> Some test entities for testing Slate components, e.g. Query Engine, Command Helper.

## Install

### Elm

Since the Elm Package Manager doesn't allow for Native code and most everything we write at Panoramic Software has some native code in it,
you have to install this library directly from GitHub, e.g. via [elm-github-install](https://github.com/gdotdesign/elm-github-install) or some equivalent mechanism. It's just not worth the hassle of putting libraries into the Elm package manager until it allows native code.

## Person Entity

The `Person` Entity has the following definition:

```elm
type alias EntirePerson =
    { name : Maybe Name
    , age : Maybe Int
    , address : Maybe EntityReference
    }
```

Here name is a Value Object:

```elm
type alias Name =
    { first : String
    , middle : String
    , last : String
    }
```

Here address is a reference to another Entity. (Done this way for testing, not necessarily good design.)

## Address Entity

The `Address` Entity has the following definition:

```elm
type alias EntireAddress =
    { street : Maybe String
    , city : Maybe String
    , state : Maybe String
    , zip : Maybe String
    }
```

## Schemas

Entities have properties. So `Schema`s define both Entity schemas and Property schemas. See [slate-common](https://github.com/panosoft/slate-common.git) for more on Schemas.
