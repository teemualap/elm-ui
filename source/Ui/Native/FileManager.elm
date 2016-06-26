module Ui.Native.FileManager exposing
  (File, readAsString, readAsDataURL, toFormData, open, download)

{-| Low level functions for managing [Files](https://developer.mozilla.org/en/docs/Web/API/File).

# Reading
@docs readAsString, readAsDataURL

# For Http
@docs toFormData

# Open / Download
@docs open, download
-}

import Http
import Task exposing (Task)

import Native.FileManager


{-| The type of the files content.
-}
type Data
  = Data


{-| Representation of a file:
  - **name** - The name of the file
  - **mimeType** - The mime type of the file
  - **size** - The size of the file
  - **data** - The file data (native File object)
-}
type alias File =
  { name : String
  , mimeType : String
  , size : Float
  , data : Data
  }


{-| Reads a file as a string.

    task = FileManager.readAsString file
-}
readAsString : File -> Task Never String
readAsString file =
  Native.FileManager.readAsString file


{-| Reads a file as a [data URI](https://en.wikipedia.org/wiki/Data_URI_scheme)

    task = FileManager.readAsDataURL file
-}
readAsDataURL : File -> Task Never String
readAsDataURL file =
  Native.FileManager.readAsDataURL file


{-| Converts a files data to Http.Data

    data = FileManager.toFormData file
-}
toFormData : String -> File -> Http.Data
toFormData key file =
  Http.stringData key (Native.FileManager.toFormData file)


{-| Opens a file browser for selecting a file.

    task = FileManager.open "image/*"
-}
open : String -> Task Never File
open accept =
  Native.FileManager.open accept


{-| Downloads the given data with the given name and mime type.

    task = FileManager.download "test.txt" "text/plain" "Hello World!"
-}
download : String -> String -> String -> Task Never String
download filename mimeType data =
  Native.FileManager.download filename mimeType data
