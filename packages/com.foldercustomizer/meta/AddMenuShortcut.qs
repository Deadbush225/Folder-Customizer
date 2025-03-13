function Component()
{
    // default constructor
}

Component.prototype.isDefault = function()
{
    // select the component by default
    return true;
}

Component.prototype.createOperations = function()
{
    // call default implementation to actually install README.txt!
    component.createOperations();

    if (systemInfo.productType === "windows") {
        component.addOperation("CreateShortcut", "@TargetDir@/bin/Printing Rates.exe", "@StartMenuDir@/Printing Rates.lnk",
            "workingDirectory=@TargetDir@", "description=Open Printing Rates");
    }
}

Component.prototype.setDescription = function()
{
    var version = installer.value("ProductVersion");
    var additionalText = " - Additional Information";

    console.log(version);

    component.description = "Main program " + version + additionalText;
}