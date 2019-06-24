# Functionality

This package adds dynamic field types for config items to OTRS.

The following types are added:

- Config item dropdown
- Config item multiselect

In dynamic fields of these types, all config items belonging to the configured class are available for selection. Note that these dynamic fields should only be used with config item classes that have less than 2000 elements.

You can also restrict the available config items by configuring the deployment status. For example, only config items of the class "Computer" could be available in a dynamic field, restricted to the deployment states "Maintenance" and "Production".

When the dynamic field is shown, the names of the selected config items are displayed.

__NOTE:__ If the deployment status in a dynamic field is reconfigured and the value stored in the object (ticket, article) is no longer available, it will be set to empty for the object during the next editing.
