function Component() {
	// default constructor
}

Component.prototype.isDefault = function () {
	// select the component by default
	return true;
};

// Component.prototype.createPage = function() {
//     var page = installer.addWizardPage("DynamicPage", "Component Version Page");

//     page.setTitle("Version Information");
//     page.setDescription("Below is the version information of selected components.");

//     var componentList = installer.components();
//     var versionModel = page.registerQmlObject("componentVersions");

//     componentList.forEach(function(component) {
//         versionModel.append({ name: component.name, version: component.version });
//     });

//     return page;
// }

Component.prototype.createOperations = function () {
	// call default implementation to actually install README.txt!
	component.createOperations();

	if (systemInfo.productType === "windows") {
		component.addOperation("CreateShortcut", "@TargetDir@/bin/FolderCustomizer.exe", "@StartMenuDir@/FolderCustomizer.lnk", "workingDirectory=@TargetDir@", "description=Open FolderCustomizer");
	}
	// gui.pageWidget().insertPage(component, "ComponentVersionPage.qml");
};

Component.prototype.setDescription = function () {
	var version = installer.value("ProductVersion");
	var additionalText = " - Additional Information";

	console.log(version);

	component.description = "Main program " + version + additionalText;
};
