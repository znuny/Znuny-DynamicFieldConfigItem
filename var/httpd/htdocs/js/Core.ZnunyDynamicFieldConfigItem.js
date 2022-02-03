// --
// Copyright (C) 2012-2021 Znuny GmbH, http://znuny.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};

/**
 * @namespace
 * @exports TargetNS as Core.ZnunyDynamicFieldConfigItem
 * @description
 *      This namespace contains the special functions for ZnunyDynamicFieldConfigItem.
 */
Core.ZnunyDynamicFieldConfigItem = (function (TargetNS) {

    /**
     * @name InitAdditionalDFStorage
     * @memberof Core.ZnunyDynamicFieldConfigItem.InitAdditionalDFStorage
     * @function
     * @param {String} DynamicFieldName - Name of dynamic field which contains the config item selection.
     * @description
     *      Initializes additional dynamic field storage for selection of config items.
     */

    TargetNS.InitAdditionalDFStorage = function (DynamicFieldName) {
        $('#DynamicField_' + DynamicFieldName).on('change', function() {
            FillAdditionalDynamicFields(DynamicFieldName);
        });
    }

    // TODO: we should use the same naming like DF-LDAP (AutoFill) or standardize these
    function FillAdditionalDynamicFields(SourceDynamicFieldName) {
        var URL  = Core.Config.Get('Baselink'),
            SelectedConfigItemIDs,
            Data = {
                Action:                 'ZnunyDynamicFieldConfigItemAJAX',
                Subaction:              'GetAdditionalDFStorageData',
                SourceDynamicFieldName: SourceDynamicFieldName,
            };

        // Support single and multi select.
        SelectedConfigItemIDs = Znuny.Form.Input.Get('DynamicField_' + SourceDynamicFieldName);
        if (typeof(SelectedConfigItemIDs) === 'string') {
            SelectedConfigItemIDs = [SelectedConfigItemIDs];
        }
        Data['SelectedConfigItemIDs'] = SelectedConfigItemIDs;

        Core.AJAX.FunctionCall(
            URL,
            Data,
            function (Response) {
                if (!Response) {
                    return;
                }

                $.each(Response, function(DestinationDynamicFieldName, Value) {
                    var FieldID   = Znuny.Form.Input.FieldID('DynamicField_' + DestinationDynamicFieldName),
                        FieldType = Znuny.Form.Input.Type(FieldID),
                        DateTimeParts;

                    if (Value && (FieldType == 'DynamicField_Date' || FieldType == 'DynamicField_DateTime')) {
                        DateTimeParts = Value.match(/^(\d{4})-(\d{2})-(\d{2})( (\d{2}):(\d{2}):(\d{2}))?$/);
                        if (DateTimeParts.length != 8) {
                            return;
                        }

                        Value = {
                            Year:   parseInt(DateTimeParts[1], 10),
                            Month:  parseInt(DateTimeParts[2], 10),
                            Day:    parseInt(DateTimeParts[3], 10),
                            Hour:   parseInt(DateTimeParts[5], 10),
                            Minute: parseInt(DateTimeParts[6], 10),
                            Used:   true,
                        };
                    }

                    Znuny.Form.Input.Set(
                        'DynamicField_' + DestinationDynamicFieldName,
                        Value
                    );
                });
            }
        );
    }

    return TargetNS;
}(Core.ZnunyDynamicFieldConfigItem || {}));
