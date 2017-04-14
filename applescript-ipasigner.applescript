set userPath to ("Macintosh HD:") as string
set userPathEnc to userPath
set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ":"}
set temp to text items of userPathEnc
set AppleScript's text item delimiters to "/"
set userPathEnc to temp as text
set AppleScript's text item delimiters to tid
set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "Macintosh HD"}
set temp to text items of userPathEnc
set AppleScript's text item delimiters to ""
set userPathEnc to temp as text
set AppleScript's text item delimiters to tid

set provPath to ("~/Desktop/profile.mobileprovision") as string

set provPathEnc to provPath
set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ":"}
set temp to text items of provPathEnc
set AppleScript's text item delimiters to "/"
set provPathEnc to temp as text
set AppleScript's text item delimiters to tid

set folderPath to ((path to desktop folder)) as string
set folderPathEnc to folderPath
set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ":"}
set temp to text items of folderPathEnc
set AppleScript's text item delimiters to "/"
set folderPathEnc to temp as text
set AppleScript's text item delimiters to tid
repeat
	display dialog "AppleScript IPA Signer" buttons {"Quit", "About", "Continue"} default button 3
	if the button returned of the result is "Quit" then
		error number -128
	else if the button returned of the result is "About" then
		display dialog "AppleScript IPA Signer written by Leon M'laiel (@Cynostial) 2017 - Licensed via MIT, do not remove Copyright Notice" & return & "All Rights Reserved" buttons {"That's awesome!"} default button 1
	else if the button returned of the result is "Continue" then
		exit repeat
	end if
end repeat
set pathChal to display dialog "Set IPA Path:" default answer folderPathEnc buttons {"Continue"} default button 1
set folderPathEnc to text returned of pathChal
set folderPath to folderPathEnc
set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "/"}
set temp to text items of folderPath
set AppleScript's text item delimiters to ":"
set folderPath to temp as text
set AppleScript's text item delimiters to tid

set folderPathNoHD to folderPathEnc
set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "Macintosh HD"}
set temp to text items of folderPathNoHD
set AppleScript's text item delimiters to ""
set folderPathNoHD to temp as text
set AppleScript's text item delimiters to tid

set fileList to paragraphs of (do shell script "ls " & folderPathNoHD & "*ipa")

repeat
	display dialog "Sign all files or one only?" buttons {"Single File", "All Files"} default button 2
	if the button returned of the result is "Single File" then
		set ipaSingle to display dialog "IPA File Name (*.ipa):" default answer "" buttons {"Continue"} default button 1
		set ipaNameSingle to text returned of ipaSingle
		set ipaName to ipaNameSingle & ".ipa"
		set ipaTrueChal to true
		exit repeat
	else if the button returned of the result is "All Files" then
		display dialog "All Files:" & return & fileList buttons {"Continue"} default button 1
		set ipaTrueChal to false
		exit repeat
	end if
end repeat
set certChal to display dialog "Signing Certificate:" default answer "iPhone Distribution: Rhett Rutledge (74FFDKA5T5)" buttons {"Continue"} default button 1
set certName to text returned of certChal
set provChal to display dialog "Provisioning Profile:" default answer provPathEnc buttons {"Continue"} default button 1
set provPathEnc to text returned of provChal

set provPath to provPathEnc

set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "/"}
set temp to text items of provPath
set AppleScript's text item delimiters to ":"
set provPath to temp as text
set AppleScript's text item delimiters to tid


repeat
	if ipaTrueChal is true then
		display dialog "Sign Info (ONE File Only):" & return & return & "IPA: " & ipaName & return & "IPA Path: " & folderPathEnc & return & return & "Certificate: " & certName & return & return & "Prov. Profile Path: " & provPathEnc buttons {"Sign " & ipaName} default button 1
		
		set payloadPathEnc to userPathEnc & "/Payload/"
		tell application "Finder"
			if exists payloadPathEnc then
				display dialog "Deleting existing Payload"
				delete payloadPathEnc
			end if
		end tell
		
		set progress total steps to 5
		set progress description to "Unzipping " & ipaName
		set progress additional description to "Codesigning " & ipaName
		
		set currentTab to do shell script ("unzip " & folderPathNoHD & ipaName) with administrator privileges
		-- repeat
		-- 	delay 1
		-- 	if not busy of currentTab then exit repeat
		-- end repeat
		
		set payloadList to paragraphs of (do shell script "ls " & userPathEnc & "/Payload/")
		set payloadListNoApp to payloadList
		set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ".app"}
		set temp to text items of payloadListNoApp
		set AppleScript's text item delimiters to ""
		set payloadListNoApp to temp as text
		set AppleScript's text item delimiters to tid
		
		set progress total steps to 10
		set progress description to "rm -rf Payload..."
		set progress additional description to "Codesigning " & ipaName
		
		set currentTab to do shell script ("rm -rf Payload/" & payloadList & "/_CodeSignature/") with administrator privileges
		-- repeat
		-- 	delay 1
		-- 	if not busy of currentTab then exit repeat
		-- end repeat
		
		-- display dialog payloadList
		
		set progress total steps to 40
		set progress description to "cp embedded.mobileprovision"
		set progress additional description to "Codesigning " & ipaName
		
		set currentTab to do shell script ("cp ~/Desktop/profile.mobileprovision Payload/" & payloadList & "/embedded.mobileprovision") with administrator privileges
		-- repeat
		-- 	delay 1
		-- 	if not busy of currentTab then exit repeat
		-- end repeat
		
		set progress total steps to 85
		set progress description to "codesign -f -s via Certificate"
		set progress additional description to "Codesigning " & ipaName
		
		set currentTab to do shell script ("codesign -f -s \"" & certName & "\" --resource-rules ~/Desktop/ResourceRules.plist Payload/" & payloadList) with administrator privileges
		-- repeat
		-- 	delay 1
		-- 	if not busy of currentTab then exit repeat
		-- end repeat
		
		set progress total steps to 90
		set progress description to "Repacking signed .ipa file"
		set progress additional description to "Codesigning " & ipaName
		
		set currentTab to do shell script ("zip -qr " & ipaNameSingle & "-resigned.ipa Payload/") with administrator privileges
		-- repeat
		-- 	delay 1
		-- 	if not busy of currentTab then exit repeat
		-- end repeat
		
		display dialog "Successfully signed " & ipaName & " as " & ipaNameSingle & "-resigned.ipa under:" & return & "Macintosh HD/" buttons {"OK"} default button 1
		
		exit repeat
	else if ipaTrueChal is false then
		display dialog "Sign Info (Multiple Files):" & return & return & "IPA(s): " & fileList & return & return & "Certificate: " & certName & return & return & "Prov. Profile Path: " & provPathEnc buttons {"Sign All Files"} default button 1
		exit repeat
	else
		display dialog "Welp.. report that to @Cynostial on Twitter..." buttons {"... no idea."} default button 1
	end if
end repeat
