function InsertUtilityDiv() { return ''; }
function BESFixletID(sid, fid) { return ''; }
function BESFixletIDToString() { return ''; }
function MakeIDListFromArray(idArray) { return ''; }
function ActivateAnalysis(analysisID) { return ''; }
function ActivateAnalyses(analysisIDArray) { return ''; }
function ReactivateAnalysis(analysisID) { return ''; }
function ReactivateAnalyses(analysisIDArray) { return ''; }
function DeactivateAnalysis(analysisID) { return ''; }
function DeactivateAnalyses(analysisIDArray) { return ''; }
function StopAction(actionID, options) { return ''; }
function StopActions(actionIDArray, options) { return ''; }
function ImportXML(xml, openDocuments, siteName, computerIDs) { return ''; }
function ImportXMLToSite(xml, siteName, openDocuments) { return ''; }
function EvaluateRelevance(expr) { return ''; }
function Relevance(expr, callback) { return ''; }
function RegisterRelevance(expr, callback, id) { return ''; }
function BooleanToText(flag) { return ''; }
function BrowseForFile(extension, filters, initialPath) { return ''; }
function BrowseForFolder(initialPath) { return ''; }
function RegisterRefreshHandler(elementID, signalName) { return ''; }
function LoadPresentation(path) { return ''; }
function GetScratchRootPath() { return ''; }
function MakeArchive(inputPath, scratchPath, recurseFlag) { return ''; }
function CopyFile(inputPath, scratchPath, allowOverwriteFlag) { return ''; }
function MoveFile(scratchPathSrc, scratchPathDest, allowOverwriteFlag) { return ''; }
function DeleteFile(scratchPath) { return ''; }
function DeleteAllFiles(scratchPath, recurseFlag) { return ''; }
function DeleteFolder(scratchPath) { return ''; }
function DeleteTree(scratchPath) { return ''; }
function MakeFolder(scratchPath) { return ''; }
function CopyFolder(inputPath, scratchPath, recurseFlag) { return ''; }
function WriteFile(text, scratchPath, appendFlag) { return ''; }
function UploadFile(inputPath, callback) { return ''; }
function UploadFileWithName(inputPath, outputPath, callback) { return ''; }
function ArchiveAndUploadFile(inputPath, outputPath, recurseFlag, callback) { return ''; }
function ArchiveAndUploadFile2(inputPath, outputPath, recurseFlag, callback) { return ''; }
function DownloadFile(url, outputPath, callback) { return ''; }
function DownloadFileWithSHA1(url, outputPath) { return ''; }
function GetFileSHA1(inputPath) { return ''; }
function GetFileSize(inputPath) { return ''; }
function GetCurrentDSN() { return ''; }
function GetCurrentUser() { return ''; }
function ManualRefresh(sectionName) { return ''; }
function ManualRefreshAll() { return ''; }
function OpenComputerGroup(cids, title) { return ''; }
function SendWakeOnLANRequest(cids) { return ''; }
function ColorizeRelevance(relevance, indent) { return ''; }
function StoreVariable(dashboardID, name, value, isPrivate) { return ''; }
function StorePrivateVariable(dashboardID, name, value) { return ''; }
function StoreSharedVariable(dashboardID, name, value) { return ''; }
function DeleteVariable(dashboardID, name, isPrivate) { return ''; }
function DeletePrivateVariable(dashboardID, name) { return ''; }
function DeleteSharedVariable(dashboardID, name) { return ''; }
function EditFixlet(fixletID, xml) { return ''; }
function DeleteFixlet(fixletID) { return ''; }
function DeleteFixlets(fixletIDs) { return ''; }
function DeleteProperty(propertyID) { return ''; }
function DeleteProperties(propertyIDs) { return ''; }
function TakeFixletAction(id, siteID, contentID, parameters, callback) { return ''; }
function TakeSecureFixletAction(id, siteID, contentID, parameters, secureParameters, callback) { return ''; }
function TakeFixletActionOnComputers(id, siteID, contentID, parameters, computerIDs, callback) { return ''; }
function TakeSecureFixletActionOnComputers(id, siteID, contentID, parameters, secureParameters, computerIDs, callback) { return ''; }
function OpenVisualization(xml) { return ''; }
function AddGlobalFilter(filterID) { return ''; }
function ClearAllGlobalFilters() { return ''; }
function ClearGlobalFilterOfType(filterType) { return ''; }
function EnableWakeOnLAN(enable) { return ''; }
function CreateCustomSite(siteName) { return ''; }
function EnableExternalSite(siteURL) { return ''; }
function AddFileToMailbox(computerID, filePath, fileName) { return ''; }
function AddFileToSite(siteNameStr, filePath, clientFile) { return ''; }
function DownloadFileEx(url, filePath, hashAlgorithm) { return ''; }
function UploadFileEx(filePath, hashAlgorithm) { return ''; }
function ArchiveAndUploadFileEx(filePath, archiveName, recurseFlag, hashAlgorithm) { return ''; }
function CompleteHashSet(hashAlgorithm, hashValue, callback) { return ''; }
function CalculateFileInfo(inputPath, callback) { return ''; }
function SiteCertificateUpdateNeeded() { return ''; }
function CreateFastQuestion(applicabilityRelevance, question ) { return ''; }
function GetFastQuestionResults( questionID, outputFormat, startElement, numberOfElements,filter  ) { return ''; }
function DoBrowseDialogWithFlags(extension, filters,
	forFolderFlag, initialPath,
	fileMustExistFlag, pathMustExistFlag,
	noValidateFlag, hideReadOnlyFlag,
	overwritePromptFlag, createPromptFlag,
	noReadOnlyReturnFlag, noTestFileCreateFlag,
	allowMultiSelectFlag) { return ''; }
