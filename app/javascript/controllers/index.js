// Controllers are picked up from the import map (see config/importmap.rb),
// so registering a new one means dropping a file into this directory.
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)
