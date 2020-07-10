# Functionality

This package adds dynamic field types for config items to OTRS.

The following types are added:

- Config item dropdown
- Config item multiselect

In dynamic fields of these types, all config items belonging to the configured class are available for selection. Note that these dynamic fields should only be used with config item classes that have less than 2000 elements.

You can also restrict the available config items by configuring the deployment status. For example, only config items of the class "Computer" could be available in a dynamic field, restricted to the deployment states "Maintenance" and "Production".

When the dynamic field is shown, the names of the selected config items are displayed.

__NOTE:__ If the deployment status in a dynamic field is reconfigured and the value stored in the object (ticket, article) is no longer available, it will be set to empty for the object during the next editing.

## Linking
Config items can be linked to tickets. As soon as a dynamic field of the above two types is created in ticket context, it can be selected which link type should be used. In addition, the link direction can be selected: config item to ticket or the other way around.

For each dynamic field of the above two types, you can select whether the links between the ticket and config item should also be removed or retained.

## Storage of additional dynamic fields
In the configuration dialog of the two new dynamic config item field types, additional dynamic fields can be configured which are automatically filled with additional data of the selected config item. If multiple config items are selected when entering ticket data in the field type 'Config item multiselect', their data will be combined if possible depending on the type of the additional dynamic field to be filled.

The respective value to be set from the config item can be referenced by a combination of field name(s) and optionally index. Examples:

1 The field 'Name' is a simple text field. In this case 'Name' is simply entered.
2. the field 'CPU' is a text field. However, several CPUs can be stored in the Config-Item. If 'CPU' is entered in the configuration, all entered CPUs are grouped together, separated by commas, depending on the type of the additional dynamic field to be filled, or in the case of a multiselect field, several are selected. If multiple storage of a CPU in the dynamic field is not possible, only the first CPU from the config item is used.
3 The 'Network Adapter' field can be filled several times. In addition, several IP addresses can be stored for each network adapter. If, for example, the third IP address of the second network adapter is to be stored in a dynamic text field, it is referenced via 'NIC::2::IP::3'.

The additional dynamic fields can be filled either directly in the frontend (i.e. in the browser, before the ticket is saved/updated) or in the backend (when the ticket is saved/updated).

### Note
Please note that during the configuration of the dynamic fields to be filled, no check is made whether a dynamic field exists or a valid config item field was referenced. Such misconfigurations are ignored when the dynamic fields are filled.

Furthermore, filling additional dynamic fields is only available for the object type Ticket. This means, for example, that dynamic fields configured for articles or customer users cannot be filled by this function. Furthermore, the configuration of additional dynamic fields is also only available if the config item selection field was also assigned to the object type Ticket.
