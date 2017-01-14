function InsertUtilityDiv() {}
function BESFixletID(sid, fid) {}
function BESFixletIDToString() {}
function MakeIDListFromArray(idArray) {}
function ActivateAnalysis(analysisID) {}
function ActivateAnalyses(analysisIDArray) {}
function ReactivateAnalysis(analysisID) {}
function ReactivateAnalyses(analysisIDArray) {}
function DeactivateAnalysis(analysisID) {}
function DeactivateAnalyses(analysisIDArray) {}
function StopAction(actionID, options) {}
function StopActions(actionIDArray, options) {}
function ImportXML(xml, openDocuments, siteName, computerIDs) {}
function ImportXMLToSite(xml, siteName, openDocuments) {}
function EvaluateRelevance(expr) {}
function Relevance(expr, callback) {}
function RegisterRelevance(expr, callback, id) {}
function BooleanToText(flag) {}
function DoBrowseDialogWithFlags(extension, filters,}
function BrowseForFile(extension, filters, initialPath) {}
function BrowseForFolder(initialPath) {}
function RegisterRefreshHandler(elementID, signalName) {}
function LoadPresentation(path) {}
function GetScratchRootPath() {}
function MakeArchive(inputPath, scratchPath, recurseFlag) {}
function CopyFile(inputPath, scratchPath, allowOverwriteFlag) {}
function MoveFile(scratchPathSrc, scratchPathDest, allowOverwriteFlag) {}
function DeleteFile(scratchPath) {}
function DeleteAllFiles(scratchPath, recurseFlag) {}
function DeleteFolder(scratchPath) {}
function DeleteTree(scratchPath) {}
function MakeFolder(scratchPath) {}
function CopyFolder(inputPath, scratchPath, recurseFlag) {}
function WriteFile(text, scratchPath, appendFlag) {}
function UploadFile(inputPath, callback) {}
function UploadFileWithName(inputPath, outputPath, callback) {}
function ArchiveAndUploadFile(inputPath, outputPath, recurseFlag, callback) {}
function ArchiveAndUploadFile2(inputPath, outputPath, recurseFlag, callback) {}
function DownloadFile(url, outputPath, callback) {}
function DownloadFileWithSHA1(url, outputPath) {}
function GetFileSHA1(inputPath) {}
function GetFileSize(inputPath) {}
function GetCurrentDSN() {}
function GetCurrentUser() {}
function ManualRefresh(sectionName) {}
function ManualRefreshAll() {}
function OpenComputerGroup(cids, title) {}
function SendWakeOnLANRequest(cids) {}
function ColorizeRelevance(relevance, indent) {}
function StoreVariable(dashboardID, name, value, isPrivate) {}
function StorePrivateVariable(dashboardID, name, value) {}
function StoreSharedVariable(dashboardID, name, value) {}
function DeleteVariable(dashboardID, name, isPrivate) {}
function DeletePrivateVariable(dashboardID, name) {}
function DeleteSharedVariable(dashboardID, name) {}
function EditFixlet(fixletID, xml) {}
function DeleteFixlet(fixletID) {}
function DeleteFixlets(fixletIDs) {}
function DeleteProperty(propertyID) {}
function DeleteProperties(propertyIDs) {}
function TakeFixletAction(id, siteID, contentID, parameters, callback) {}
function TakeSecureFixletAction(id, siteID, contentID, parameters, secureParameters, callback) {}
function TakeFixletActionOnComputers(id, siteID, contentID, parameters, computerIDs, callback) {}
function TakeSecureFixletActionOnComputers(id, siteID, contentID, parameters, secureParameters, computerIDs, callback) {}
function OpenVisualization(xml) {}
function AddGlobalFilter(filterID) {}
function ClearAllGlobalFilters() {}
function ClearGlobalFilterOfType(filterType) {}
function EnableWakeOnLAN(enable) {}
function CreateCustomSite(siteName) {}
function EnableExternalSite(siteURL) {}
function AddFileToMailbox(computerID, filePath, fileName) {}
function AddFileToSite(siteNameStr, filePath, clientFile) {}
function DownloadFileEx(url, filePath, hashAlgorithm) {}
function UploadFileEx(filePath, hashAlgorithm) {}
function ArchiveAndUploadFileEx(filePath, archiveName, recurseFlag, hashAlgorithm) {}
function CompleteHashSet(hashAlgorithm, hashValue, callback) {}
function CalculateFileInfo(inputPath, callback) {}
function SiteCertificateUpdateNeeded() {}
function CreateFastQuestion(applicabilityRelevance, question ) {}
function GetFastQuestionResults( questionID, outputFormat, startElement, numberOfElements,filter  ) {}
