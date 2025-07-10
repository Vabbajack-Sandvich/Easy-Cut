-- Easy Cut, an extension for VLC, to store your Cuts
-- 2024g3a
------------------------------------------------
-- Global variables
minsec_display=1
 -- 1	xx:xx:xx hours:minutes:seconds (default)
 -- 0	xxx per thousands of medium duration
vlc_version=1
-- 0 reads VLC version in vlcrc settings file (default)
-- 4 enforces VLC version 4
medium_name_predefined="??"
-- "??" starts with Media management (default)
-- "" takes VLC detected medium name directly to the Cuts window (to Media magt if no medium playing)
maxtrainer=300			-- nr of elements to "train" the tmsorted table of displayed lists
mshow_list={}
table_save_lmed={}
ztable_save_l={}
tnames={}
nmeds=0
selected_med=""
main_layout=nil
enter_text_label=nil
caption_text_input=nil
confirm_capted=nil
err_label=nil
info_med1=nil
info_med2=nil
simodif=false
bokmed=false
printd=true
capencours=false
affinfomed=false
affreverse=false
afferr=false
medium_name=""
medium_uri=""
badloop=0
mediumidx=0
znmstart=0
dectoCutname=0
currCut=0
tCutname={}
tCutpos={}
tCutch={}
tCutem={}
tmsorted={}
checkpoint_l=nil
imp_button=nil
check_xspf=nil
checkpos=0
checkposch=""
checktimech=""
checkch=""
destination=""
tdur=0
zspeed="1"
zerr="none"

function descriptor()
	return {
	title = "Easy Cut",
	-- original version
	-- 2024g3a
	version = "2025-4-20",
	author = "originally - A Rashed + jpcare and then vabbajacksandvich for easy cut", -- original design and coding by ARahman Rashed, reworked & extended by JP Carillon
	--original url
	--url = 'https://addons.videolan.org/p/1848670',
	url = '',
	shortdesc = "Easy Cut",
	description = "This version is not anything like Bookmark Moments, I just used their code as a base and changed it. This converts VLC into a video editor by generating ffmpeg commands for batch files based on the time cuts that were made in the list. This change to this extension makes it generate ffmpeg commands using the time you paused the video at and clicked the cut button. Example: ffmpeg -y -ss 00:00:00 -to 00:20:00 -i 2025-02-28_19-23-21.mp4 -c:v libx264 -crf 20 -preset ultrafast -r 60 2025-02-28_19-23-21_uf_t_1_1x.mp4. It exports them to the memos.txt file in the appdata VLC folder. It automatically generates: new output filenames with what cut revision and what speed, it keeps track of where the time left off between commands, it also generates an end command that automatically fills in from where you made your last cut to the very end of the file length.",
	capabilities = {"menu", "input-listener", "meta-listener", "playing-listener"}
	}
end

function checkversion()	-- VLC 3 misc.version() crashes
	local file
	local vlconf
	local chcar
	local chcarsup
	local versionlue
	local k,kf
	vlconf=vlc.config.configdir().."/vlcrc"
	file=io.open(vlconf)
	if file then
		for line in file:lines() do
			if line then
				k,kf=string.find(line,"###	vlc %d")
				if k==1 then
					chcar=string.sub(line,10,10)
					if (#(line)>10) then
						chcarsup=string.sub(line,11,11)
						if tonumber(chcarsup) then chcar=chcar..chcarsup end
					end
					versionlue=tonumber(chcar)
					if versionlue then
						if versionlue<4 then
							if vlc_version<4 then vlc_version=0
							else vlc_version=4 end
						else vlc_version=4 end
					end
					break
				end
			else break end
		end
		file:close()
	end
end

function get_basic_data()
	if vlc_version<4 then
		input=vlc.object.input()
		medium_name=vlc.input.item():name()
		medium_uri=vlc.input.item():uri()
		-- no metas for track in DVD
		tdur=vlc.input.item():duration()
		else
		player=vlc.object.player()
		medium_name=vlc.player.item():name()
		medium_uri=vlc.player.item():uri()
		tdur=vlc.player.item():duration()
	end
end

function display_impossible()
	error_dialog=vlc.dialog("Unusable or blank medium")
	error_dialog:add_label("Please open a medium file/cd/dvd.. no live stream !")
end

function display_badfile()
	error_dialog=vlc.dialog("Data corruption")
	error_dialog:add_label("Your easy_cut.txt database cannot be used")
	error_dialog:add_label("Bad line ["..badloop.."] in file")
end

function kwickfileok()
	local filepass=true
	local file=io.open(destination)
	if file then
		local balance=true
		local k,kf
		local ntilde
		badloop=-1
		for line in file:lines() do
			if balance then	-- medium line
				badloop=badloop+2
				filepass=false
				k,kf=string.find(line,"~")
				if k>1 then
					ntilde=0
					for w in string.gmatch(line,"~") do ntilde=ntilde+1 end
					if ntilde==3 then -- 3 fields exactly
						if not(string.find(line,"*&",k)) then filepass=true end -- no mix with Cuts
					end
				end
			end
			if filepass then balance=not(balance)
			else break end
		end
		file:close()
	end
	if filepass then badloop=0 end
	return filepass
end

function checkmedium()
	bokmed=pcall(get_basic_data)
	if bokmed then
		if not(tdur>0) or (#(corename(medium_name))<1) then
			bokmed=false
			display_impossible()
		else
			medium_name=string.gsub(medium_name,"~","_")
		end
	end
end

function activate()
	destination=vlc.config.userdatadir().."/easy_cut.txt"
	if not(kwickfileok()) then
		display_badfile()
		return 0
	end
	checkversion()
	checkmedium()
	simodif=false
	if minsec_display>0 then dectoCutname=10
	else dectoCutname=5 end
	load_media_tables()
	if not(bokmed) or (medium_name_predefined=="??") then
		MediaGUI()
	else
		ToCutsGUI(0)
	end
	-- i think this is where i can add code to start up
	-- maybe fix whatever that button issue is
	-- where when you click one of the 1 x 2 x buttons
	-- you have to click it 1 time every time and
	-- it seems like it does nothing the first time
	
	-- so if i put the button click code here
	-- and run it the first time
	-- or on the window that defines it
	-- or when the window that holds it loads
	
	-- 935 ish is the confirm_caption function
	-- that all the 1x 2x buttons call
	
	--zconfirm_caption()
	
end

function close()
	if capencours then exitpause() end
	vlc.deactivate()
end

function deactivate()
	save_database()
end

function save_database()
	if simodif then	-- rewrite full database
		simodif=false
		local temp=destination.."_copy"..os.date("%Y%m%d%H%M%S")
		local bos=os.rename(destination,temp)
		local file=io.open(destination,"w+")
		local i=0
		local nullfound=false
		while i<nmeds do
			i=i+1
			if #(tnames[i])>0 then
				file:write(table_save_lmed[i],"\n",ztable_save_l[i],"\n")
			else
				nullfound=true
			end
		end
		file:flush()
		file:close()
		if bos then bos=os.remove(temp) end
		if nullfound then -- log removed media
			local dest,sint
			local ch=""
			local iend,kf
			i=0
			while i<nmeds do
				i=i+1
				if #(tnames[i])==0 then
					sint=table_save_lmed[i]
					if #(sint)>0 then
						if #(ch)==0 then
							dest=vlc.config.userdatadir().."/easy_cut_deletelog.txt"
							file=io.open(dest,"a+")
							file:seek("end")
							file:write(os.date("%Y/%m/%d %H:%M").."\n")
						end
						iend,kf=string.find(sint,"~")
						iend=iend-1
						ch=string.sub(sint,1,iend)
						iend=iend+1
						ch=ch..os.date("%Y%m%d%H%M%S")..string.sub(sint,iend)
						file:write(ch,"\n",ztable_save_l[i],"\n","================\n")
						table_save_lmed[i]=""
					end
				end
			end
			if #(ch)>0 then
				file:flush()
				file:close()
			end
		end
	end
end

function load_media_tables()
-- Loads easy_cut.txt database into tables
-- Database : 2 lines per medium
-- medium_name ~ checkpoint data
-- nil or list of Cuts
	local balance=true
	local sint=""
	local k,kf
	local file
	nmeds=0
	file=io.open(destination)
	if file then
		for line in file:lines() do
			if balance then
				k,kf=string.find(line,"~")
				sint=string.sub(line,1,(k-1))
				nmeds=nmeds+1
				tnames[nmeds]=sint
				table_save_lmed[nmeds]=line
				ztable_save_l[nmeds]=""
			else
				ztable_save_l[nmeds]=line
			end
			balance=not(balance)
		end
		file:close()
	end
	k=0
	while k<maxtrainer do
		k=k+1
		rawset(tmsorted,k," "..k)
	end
	while k>0 do
		table.remove(tmsorted)
		k=k-1
	end
end

function check_medium_name()
	local sint=medium_name_predefined
	sint=corename(sint)
	if #(sint)>1 then
		if not(string.find(sint,"~")) then
			medium_name_predefined=sint
			return 1
		end
	end
	return 0
end

function killblanks(chin)
	local sout=""
	local len=#(chin)
	local i=0
	while i<len do
		i=i+1
		if string.sub(chin,i,i)~=" " then
			sout=string.sub(chin,i,len)
			break
		end
	end
	return sout
end

function corename(inchin) -- extra blanks
	local sout=inchin
	if #(sout)>0 then sout=killblanks(sout) end
	if #(sout)>0 then sout=killblanks(string.reverse(sout)) end
	if #(sout)>1 then sout=string.reverse(sout) end
	return sout
end

function select_nop()
	return
end

function cleanerr()
	if afferr then
			main_layout:del_widget(err_label)
			afferr=false
	end
end

function zerrdis()
--this is my error display
--zerr is a global that i set to whichever error
	--err_label=main_layout:add_label(zerr,1,11,4)
	local zlisttotal=tablelength(tmsorted)
	if zlisttotal>0 then
		mshow_list:add_value(zerr,zlisttotal-1)
	end
end

function cleaninfomed()
	if affinfomed then
		main_layout:del_widget(info_med2)
		main_layout:del_widget(info_med1)
		affinfomed=false
	end
end

function oneselected(koko)
	local tidx=0
	cleanerr()
	local selexam=mshow_list:get_selection()
	if not(selexam) then	-- test or not ?
		return nil,tidx
	end
	local ifirst=true
	local selec=nil
	for idx,selectedItem in pairs(selexam) do
		tidx=idx
		if ifirst then
			selec=selectedItem
			ifirst=false
		else
			selec=nil
			break
		end
	end
	if not(selec) then
		if koko>0 then showkerr(7) end
	end
	return selec,tidx
end

function select_med_exit()
	if capencours then return end
	ToCutsGUI(1)
end

function select_med_line()
	if capencours then return end
	local sel,ri
	sel,ri=oneselected(1)
	if not(sel) then return end
	medium_name=sel
	ToCutsGUI(1)
end

function capture_med()
	if capencours then return end
	capencours=true
	local chint,ri
	chint,ri=oneselected(0)
	if not(chint) then
		chint=""
	end
	if #(chint)==0 and #(medium_name)>0 then chint=medium_name end
	enter_text_label=main_layout:add_label("<b><i>NEW medium name </i></b>	--->",1,2,1)
	caption_text_input=main_layout:add_text_input(chint,2,2,5)
	confirm_capted=main_layout:add_button("OK",confirm_med,7,2,1)
end

function confirm_med()
	local caption_text
	cleanerr()
	caption_text=caption_text_input:get_text()
	if caption_text==nil then caption_text="	" end
	if #(caption_text)==0 then caption_text="	" end
	medium_name_predefined=caption_text
	local rcheck=check_medium_name()
	main_layout:del_widget(enter_text_label)
	main_layout:del_widget(caption_text_input)
	main_layout:del_widget(confirm_capted)
	if rcheck<1 then
		capencours=false
		showkerr(1)
	else
		medium_name=medium_name_predefined
		ToCutsGUI(1)
	end
end

function confirm_changemed()
	local caption_text
	cleanerr()
	caption_text=caption_text_input:get_text()
	if caption_text==nil then caption_text="	" end
	if #(caption_text)==0 then caption_text="	" end
	medium_name_predefined=caption_text
	local recheck=check_medium_name()
	caption_text=medium_name_predefined
	main_layout:del_widget(enter_text_label)
	main_layout:del_widget(caption_text_input)
	main_layout:del_widget(confirm_capted)
	if recheck<1 then
		showkerr(1)
		capencours=false
		return
	end
	if caption_text==selected_med then capencours=false return 1 end
	if findia(caption_text)>0 then
		capencours=false
		err_label=main_layout:add_label("<b><font color=darkred>This medium name already exists !</font></b>",1,2,3)
		afferr=true
		return
	end
	local k,kf
	local i=findia(selected_med)
	if i>0 then
		local lineref=table_save_lmed[i]
		k,kf=string.find(lineref,"~")
		lineref=caption_text..string.sub(lineref,k)
		table_save_lmed[i]=lineref
		tnames[i]=caption_text
		simodif=true
		display_media_names(2)
	end
	capencours=false
end

function dup_med_line()
	if capencours then return end
	local sel,ri
	sel,ri=oneselected(1)
	if not(sel) then return end
	local i=findia(sel)
	if i>0 then
		local dupname=sel..os.date("%Y%m%d%H%M%S")
		nmeds=nmeds+1
		tnames[nmeds]=dupname
		lineref=table_save_lmed[i]
		local shnt=string.reverse(lineref)
		k,kf=string.find(shnt,"~")
		shnt=string.sub(shnt,k)
		lineref=string.reverse(shnt)..os.date("%Y/%m/%d")
		k,kf=string.find(lineref,"~")
		lineref=dupname..string.sub(lineref,k)
		table_save_lmed[nmeds]=lineref
		ztable_save_l[nmeds]=ztable_save_l[i]
		simodif=true
		display_media_names(2)
	end
end

function remove_med_line()
	if capencours then return end
	local sel,ri
	sel,ri=oneselected(1)
	if not(sel) then return end
	cleaninfomed()
	local i=findia(sel)
	if i>0 then
		tnames[i]=""
		simodif=true
		table.remove(tmsorted,ri)
		display_media_names(0)
	end
end

function change_med_line()
	if capencours then return end
	capencours=true
	local sel,ri
	sel,ri=oneselected(1)
	if not(sel) then capencours=false return end
	selected_med=sel
	if bokmed then
	enter_text_label=main_layout:add_label("<b><i>SUBSTITUTE name </i></b>		--->",1,2,1)
	caption_text_input=main_layout:add_text_input(sel,2,2,5)
	else
	enter_text_label=main_layout:add_label("<b><i>SUBSTITUTE name </i></b>		--->",1,2,2)
	caption_text_input=main_layout:add_text_input(sel,3,2,4)
	end
	confirm_capted=main_layout:add_button("OK",confirm_changemed,7,2,1)
end

function info_med_line()
	local sel,ri
	sel,ri=oneselected(1)
	if not(sel) then return end
	local ient=findia(sel)
	if ient==0 then return end
	cleaninfomed()
	local sline=table_save_lmed[ient]
	local infodate=""
	local infopoint=""
	local cna="NA"
	for ch0,v,ch1,ch2 in string.gmatch(sline,"(.+)~(.+)~(.+)~(.+)") do
		infopoint=ch1
		infodate=ch2
	end
	if #(infodate)==0 then infodate=cna
	else -- obsolete content
		if tonumber(string.sub(infodate,1,1))==nil then infodate=cna end
		if string.find(infodate,":") then infodate=cna end
	end
	if #(infopoint)==0 then infopoint=cna
	else
		local i,kf
		i,kf=string.find(infopoint," ")
		if i then
			if i>1 then infopoint=string.sub(infopoint,1,(i-1)) end
		end
	end
	local infoCut=0
	sline=ztable_save_l[ient]
	if sline then
		for w in string.gmatch(sline,"*&") do
			infoCut=infoCut+1
		end
	end
	local aff="<b><i>"..sel.."</i></b>"
	info_med1=main_layout:add_label(aff,1,9,7)
	aff=os.date("%Y/%m/%d")
	if infopoint==aff then infopoint="today" end
	if infodate==aff then infodate="today" end
aff="<i>Nr of stored Cuts ["..infoCut.."] Medium ["..infodate.."] Checkpoint ["..infopoint.."]</i>"
	info_med2=main_layout:add_label(aff,1,10,7)
	affinfomed=true
end

function display_media_names(ksor)
	local k=0
	local kaff=0
	if ksor>0 then
		while k<nmeds do
			k=k+1
			if #(tnames[k])>0 then
				kaff=kaff+1
				rawset(tmsorted,kaff,tnames[k])
			end
		end
		if kaff>1 then
			table.sort(tmsorted)
		end
	else
		while k<nmeds do
			k=k+1
			if #(tnames[k])>0 then
				kaff=kaff+1
			end
		end
	end
	k=0
	mshow_list:clear()
	while k<kaff do
		k=k+1
		mshow_list:add_value(tmsorted[k],k)
	end
end

function MediaGUI()
	capencours=false
	affinfomed=false
	afferr=false
	main_layout=vlc.dialog("Media management")
	main_layout:add_label(" ",1,2)
	main_layout:add_label("<b>List of <font color=darkred>MEDIA names</font></b> in database",1,3,7)
	main_layout:add_button("",select_nop,1,5,1)	--ghost default
	if bokmed then
		main_layout:add_button("Start with VLC detected name ",select_med_exit,1,5,1)
		main_layout:add_button("Start with selected name ",select_med_line,2,5,1)
		main_layout:add_button(" Start with a new name ",capture_med,3,5,1)
	else
		main_layout:add_button("NOP",select_nop,1,5,1)
		main_layout:add_button("NOP",select_nop,2,5,1)
		main_layout:add_button("NOP",select_nop,3,5,1)
	end
	main_layout:add_button(" Info/selected ",info_med_line,4,5,1)
	main_layout:add_button(" Rename selected ",change_med_line,5,5,1)
	main_layout:add_button(" Duplicate selected ",dup_med_line,6,5,1)
	main_layout:add_button(" Delete selected ",remove_med_line,7,5,1)
	main_layout:add_label("<hr>",1,6,7,1)
	if bokmed then
		main_layout:add_label("<font color=darkred>VLC detected name</font> : "..medium_name,1,7,7,1)
	else
		main_layout:add_label("<font color=darkred>No playing medium</font>",1,7,7)
	end
	main_layout:add_label("<hr>",1,8,7,1)
	mshow_list=main_layout:add_list(1,4,7)
	main_layout:show()
	display_media_names(1)
	
	--adding this
	--to try to click the button
	--the first time
	--zconfirm_caption()
	
	select_med_exit()
	--zconfirm_caption()
	
end

function ToCutsGUI(medwin)
	if medwin>0 then
		cleanerr()
		cleaninfomed()
		main_layout:delete()
		save_database()
		local k=#(tmsorted)
		while k>0 do
			table.remove(tmsorted)
			k=k-1
		end
	end
	load_medium_data()
	CutsGUI()
end

function CutsGUI()

	zerr="farts - cutsgui function"
	zerrdis()

	capencours=false
	affreverse=false
	afferr=false
	printd=true
	currCut=0
	--main_layout=vlc.dialog("Cuts & checkpoint")
	main_layout=vlc.dialog("Easy Cut")
	main_layout:add_label(" ",1,2)
	main_layout:add_label("<b> Cuts </b>",1,3,2)
	--main_layout:add_label("<i>(close/restart the extension at will)</i>",3,3,2)
	--main_layout:add_button("",select_nop,1,5,1) --ghost default
	--main_layout:add_button(" Capture Cut ",capture_Cut,1,5,1)
	main_layout:add_button(" Jump to Cut ",jump_to_Cut,2,5,1)
	main_layout:add_button(" Remove Cut ",remove_Cut,3,5,1)
	--main_layout:add_button(" Reverse List ",antilist,4,5,1)
	--info_med2=main_layout:add_label(" ",1,6,4)
	--main_layout:add_label("<b>Recorded checkpoint : </b>",1,7,1)
	--checkpoint_l=main_layout:add_label("",2,7,2)
	--display_checkpoint_data()
	--main_layout:add_button(" Checkpoint! ",mark_position,1,8,1)
	--main_layout:add_button(" Jump to Checkpoint ",jump_to_checkpoint,2,8,1)
	--main_layout:add_button(" [MEDIA] ",back_tomedia,4,8,1)
	--main_layout:add_label("<font color=darkred>Medium name</font> : ".. medium_name,1,9,4,1)
	mshow_list=main_layout:add_list(1,4,4)
	main_layout:show()
	display_Cuts(1)
		
	--adding this from capture Cut
	--enter_text_label=main_layout:add_label("<b><i>Name New Cut</i></b> ---->",1,2,1)
	--caption_text_input=main_layout:add_text_input(sint,2,2,2)
	--caption_text_input:set_text("11")
	confirm_capted=main_layout:add_button("1x",zconfirm_caption,1,2,1)
	confirm_capted2=main_layout:add_button("2x",zconfirm_caption2,2,2,1)
	confirm_capted4=main_layout:add_button("4x",zconfirm_caption4,3,2,1)
	confirm_capted8=main_layout:add_button("8x",zconfirm_caption8,4,2,1)
	
	--zconfirm_caption()
end

function display_checkpoint_data()
	--i deleted this is the problem i think
	if checkposch~="" then
		checkpoint_l:set_text("<i>"..checktimech.."</i> --- <b>"..checkposch.."</b>")
	else
		checkpoint_l:set_text("<i> No checkpoint marked for this medium</i>")
	end
end

function remindin()
	enter_text_label:set_text("<b><u><font color=darkred>Name New Cut</font></u></b> ---->")
end

function back_tomedia()
	if capencours then
		remindin()
		return
	end
	cleanerr()
	if check_xspf then main_layout:del_widget(check_xspf) end
	if imp_button then main_layout:del_widget(imp_button) end
	main_layout:delete()
	checkmedium()
	local k=znmstart
	while k>0 do
		table.remove(tmsorted)
		k=k-1
	end
	MediaGUI()
end

function save_checkpoint()
	if mediumidx<1 then	-- new medium entry
		nmeds=nmeds+1
		mediumidx=nmeds
		tnames[nmeds]=medium_name
		checkch=os.date("%Y/%m/%d")
	end
	table_save_lmed[mediumidx]=medium_name.."~"..checkpos.."~"..checktimech.."~"..checkch
	if znmstart<1 then
		ztable_save_l[mediumidx]="nil"
	end
	simodif=true
	--display_checkpoint_data()
end

function findia(sme)
	local chn=sme
	local i=nmeds
	while i>0 do
		if rawequal(chn,tnames[i]) then break end
		i=i-1
	end
	return i
end

function load_medium_data()
-- Checkpoint and Cuts of current medium for display
	local linem,chunk,cha,chb
	local ideb,ifound,idf,ik,len
	local pom
	mediumidx=0
	znmstart=0
	checkposch=""
	if nmeds==0 then return end
	mediumidx=findia(medium_name)
	if mediumidx==0 then return end
	linem=table_save_lmed[mediumidx]
	ideb,idf=string.find(linem,"~")
	ideb=ideb+1
	ik,idf=string.find(linem,"~",ideb)
	checkpos=torealnum(string.sub(linem,ideb,(ik-1)))
	checkposch=formatpos(checkpos)
	ideb=ik+1
	ik,idf=string.find(linem,"~",ideb)
	checktimech=string.sub(linem,ideb,(ik-1))
	checkch=string.sub(linem,(ik+1))
	linem=ztable_save_l[mediumidx]
	ifound,idf=string.find(linem,"*&")
	ideb=1
	len=#linem-2
	while ifound do
		chunk=string.sub(linem,ideb,(ifound-1))
		ideb=ifound+2
		ik,idf=string.find(chunk,"~")
		if ik then
			cha=string.sub(chunk,1,(ik-1))
			if #cha>0 then
				chb=string.sub(chunk,(ik+1))
				znmstart=znmstart+1
				tCutem[znmstart]=chunk.."*&"
				tCutname[znmstart]=cha
				pom=torealnum(chb)
				tCutpos[znmstart]=pom
				tCutch[znmstart]=formatpos(pom).." "..cha
			end
		end
		if ideb<len then
			ifound,idf=string.find(linem,"*&",ideb)
		else break end
	end
end

function torealnum(vv)
	local rnum
	if #(vv)>=8 then -- 6 digits fraction unit < 1 s in 100 H
			rnum=tonumber(string.sub(vv,3,8))
			if rnum then
				return (rnum * 0.000001)
			else return 0 end
	end
	local lenv=#(vv)
	if lenv>2 then
		if string.sub(vv,1,1)=="0" then
				rnum=tonumber(string.sub(vv,3,lenv))
				if rnum then
					return (rnum/ (math.pow(10,(lenv-2))))
				else return 0 end
		else
			if string.sub(vv,1,1)=="1" then return 1 end
		end
	else
		if string.sub(vv,1,1)=="1" then return 1 end
	end
	return 0
end

function tostraff2(n2d)		-- tostring 2 d
	local nd,nu
	nu=n2d % 10
	nd=(n2d-nu)/10
return string.char((nd+48),(nu+48))
end

function tostraff3(n3d)		-- tostring 3 d
	local ntop,nu,nd,nc
	nu=n3d % 10
	ntop=(n3d-nu) / 10
	nd=ntop % 10
	nc=(ntop-nd) / 10
return string.char((nc+48),(nd+48),(nu+48))
end

function formatpos(position)
	if minsec_display>0 then
			local grandm
			local totsec=tdur*position
			local grandh=math.floor(totsec/3600)
			local restsec=totsec-(3600*grandh)
			if restsec<0 then restsec=0 end
			if grandh>=100 then
				return "::::::::"
			else
				grandm=math.floor(restsec/60)
				restsec=restsec-(60*grandm)
				if restsec<0 then restsec=0 end
				restsec=math.floor(restsec)
				return tostraff2(grandh)..":"..tostraff2(grandm)..":"..tostraff2(restsec)
			end
	else
		local pourmil=math.floor(position*1000+0.5)
		if pourmil>=1000 then pourmil=999 end
		return tostraff3(pourmil)
	end
end

function mark_position()
	if capencours then
		remindin()
		return
	end
	if vlc_version<4 then
		checkpos=vlc.var.get(input,"position")
	else
		checkpos=vlc.player.get_position()
	end
	checkposch=formatpos(checkpos)
	checktimech=os.date("%Y/%m/%d %H:%M:%S")
	save_checkpoint()
	--exitpause()
	cleanerr()
end

function exitpause()
	
	if not(vlc.playlist.status()=="playing") then
		vlc.playlist.pause()	-- toggle
	end
	
	--return
end

function jump_to_checkpoint()
	if capencours then
		remindin()
		return
	end
	exitpause()
	if vlc_version<4 then
		vlc.var.set(input,"position",checkpos)
	else
		vlc.player.seek_by_pos_absolute(checkpos)
	end
	cleanerr()
end

function capture_Cut()
	if capencours then
		remindin()
		return
	end
	capencours=true
	local sint,ri
	sint,ri=oneselected(0)
	if not(sint) then
		sint=""
	else sint=string.sub(sint,dectoCutname) end
	if vlc.playlist.status()=="playing" then
		vlc.playlist.pause()
	end
	--[[
	enter_text_label=main_layout:add_label("<b><i>Name New Cut</i></b> ---->",1,2,1)
	caption_text_input=main_layout:add_text_input(sint,2,2,2)
	confirm_capted=main_layout:add_button("SAVE IT",confirm_caption,4,2,1)
	]]
	confirm_caption()
end

	--this sets the zspeed variable to 1 2 4 or 8
	--which is for upgrading the mod to
	--include whichever button

function zconfirm_caption()
	zspeed="1"
	confirm_caption()
end

function zconfirm_caption2()
	zspeed="2"
	confirm_caption()
end

function zconfirm_caption4()
	zspeed="4"
	confirm_caption()
end

function zconfirm_caption8()
	zspeed="8"
	confirm_caption()
end

function confirm_caption()
	local caption_text
	local kaka=false
	local bad=true
	local zmstart
	--using this for debugging
	--red label on the bottom of the window
	--local zerr="none"
	--this clears it
	--main_layout:del_widget(err_label)
	
	--caption_text=caption_text_input:get_text()
	--caption_text="1x"
	caption_text=zspeed.."x"

	if caption_text==nil then
		caption_text=" "
		zerr="caption text nil"
		zerrdis()
	end
	if string.find(caption_text,"*&") then
		caption_text=" "
		kaka=true
		zerr="caption text empty and kaka true found ampersand"
		zerrdis()
	else
		if string.find(caption_text,"~") then
			caption_text=" "
			zerr="caption text nil no kaka found tilde"
			zerrdis()
		end
	end
	--these were non commented
	--main_layout:del_widget(enter_text_label)
	--main_layout:del_widget(caption_text_input)
	--main_layout:del_widget(confirm_capted)
	
	if #(caption_text)>1 then
		bad=false
		zerr="#caption_text > 1 = "..caption_text
		zerrdis()

		if vlc_version<4 then
			zmstart=vlc.var.get(input,"position")
		else
			zmstart=vlc.player.get_position()
		end
		if not(zmstart) then
			zmstart=0
		end
		local sint=formatpos(zmstart)
		if checkposch=="" then
			checkpos=zmstart
			checkposch=sint
			checktimech=os.date("%Y/%m/%d %H:%M:%S")
			save_checkpoint()
		end
		sint=sint.." "..caption_text
		znmstart=znmstart+1
		tCutname[znmstart]=caption_text
		tCutpos[znmstart]=zmstart
		tCutch[znmstart]=sint
		sint=caption_text.."~"..tostring(zmstart).."*&"
		tCutem[znmstart]=sint
		if znmstart==1 then
			ztable_save_l[mediumidx]=sint
		else
			ztable_save_l[mediumidx]=ztable_save_l[mediumidx]..sint
		end
		
		simodif=true
	end
	
	if bad then
		if kaka then showkerr(2)
		else showkerr(1) end
	else
		display_Cuts(2)
	end
	capencours=false
	--exitpause()
end

-- end confirm_caption

function display_Cuts(ksor)

	--testing zerrdis
	zerr="farts - display cuts"
	zerrdis()

	local k=0
	if ksor>0 then
		while k<znmstart do
			k=k+1
			rawset(tmsorted,k,tCutch[k])
		end
		if znmstart>1 then
			table.sort(tmsorted)
		end
	end
	mshow_list:clear()
	if affreverse then
		k=znmstart
		while k>0 do
			mshow_list:add_value(tmsorted[k],k)
			k=k-1
		end
	else
		k=0
		while k<znmstart do
			k=k+1
			mshow_list:add_value(tmsorted[k],k)
		end
	end
	if printd then
		local kf
		printd=false
		imp_button=main_layout:add_button(" Export Cuts ",memosave,1,10,4)
		k,kf=string.find(medium_uri,"file:///")
		--i think this adds the checkbox
	--im commenting it out
	--if k==1 then check_xspf=main_layout:add_check_box("playlist ",false,4,10,1)
		--else check_xspf=nil end
	--this line wasnt here
	check_xspf=nil
	--yeah no more playlist box
	--and the export button stays there and continues working
	end
end

function antilist()
	cleanerr()
	affreverse=not(affreverse)
	display_Cuts(0)
end

function findmo(smo)
 local chn=smo
 local icher=znmstart
 while icher>0 do
		if rawequal(chn,tCutch[icher]) then
			break
		end
		icher=icher-1
 end
 return icher
end

function jump_to_Cut()
	if capencours then
		remindin()
		return
	end
	local sel,ri,isel
	sel,ri=oneselected(1)
	if not(sel) then
		if (ri==0) and (znmstart>0) then
			cleanerr()
			currCut=currCut+1
			if (currCut<=0) or (currCut>znmstart) then
				currCut=1
			end
			sel=tmsorted[currCut]
			--info_med2:set_text("<i><font color=darkblue>"..sel.."</font></i>",1,6,4)
		else
			return
		end
	else
		--info_med2:set_text("<i><font color=darkblue>"..tmsorted[ri].."</font></i>",1,6,4)
		currCut=ri
	end
	isel=findmo(sel)
	exitpause()
	if vlc_version<4 then
		vlc.var.set(input,"position",tCutpos[isel])
	else
		vlc.player.seek_by_pos_absolute(tCutpos[isel])
	end
end

function remove_Cut()
	if capencours then
		remindin()
		return
	end
	local sel,ri
	sel,ri=oneselected(1)
	if not(sel) then return end
	local isel=findmo(sel)
	if isel>0 then
		if isel<znmstart then
			tCutname[isel]=tCutname[znmstart]
			tCutpos[isel]=tCutpos[znmstart]
			tCutch[isel]=tCutch[znmstart]
			tCutem[isel]=tCutem[znmstart]
		end
		znmstart=znmstart-1
		if znmstart<1 then
			ztable_save_l[mediumidx]="nil"
		else
			ztable_save_l[mediumidx]=table.concat(tCutem,"",1,znmstart)
		end
		simodif=true
		if currCut>=ri then
			currCut=currCut-1
		end
		--get selection before deletion
	--local zselexam=mshow_list:get_selection()

		table.remove(tmsorted,ri)
	
	--get new total
	--local zlisttotal=mshow_list:count()
	--no set selected method?
	--checked vlc source for methods for widgets
	--doesnt have them and id have to add them
	--dialog.c - line 125
	--[[
	local zlisttotal=tablelength(tmsorted)
	
		if (zlisttotal>0) then
			if (ri<=zlisttotal) then
				mshow_list:setselection(ri)
			end
		end
	]]
	display_Cuts(0)
	end
	--exitpause()
end

function memosave()
	if capencours then
		remindin()
		return
	end
	local doxspf=false
	local dest
	local file
	local k
	local tms={}
	--this is for debugging to add a second array
	--for outputting to see what the rawget does
	local ztms={}

	--string for trimming the time codes
	local zstrtc
	zstrtc=""
	--for previous entry
	local zstrtcp
	zstrtcp=""
	--for temp string pulling
	local zstrtsp
	zstrtsp=""
	--for finalout
	local zstrout
	zstrout=""
	--for trimming the .mp4 off the end for the output
	local zstrmed
	zstrmed=string.sub(medium_name,1,-5)
	local zstrfs
	zstrfs=""
	k=0
	while k<znmstart do
		k=k+1
	
	--old
	--tms[k]=rawget(tmsorted,k)
	
	--new
	--uses a temp string to store the pulled entry
	--then adds the final output to the array
	--that the rest of the code uses
	
	zstrtsp=tostring(rawget(tmsorted,k))

	--output from ahk
	--zffplstr := zffplstr "`nffmpeg -y -ss 00:00:00 -to 00:00:00 -i " zffn " -c:v libx264 -crf 20 -preset ultrafast " zffn2 "_uf_trimmed-" zffi ".mp4`n"
	--this script uses this variable for the file name
	--medium_name
	--"ffmpeg -y -ss 00:00:00 -to 00:00:00 -i " medium_name " -c:v libx264 -crf 20 -preset ultrafast " medium_name "_uf_trimmed-" k ".mp4"
	--"ffmpeg -y -ss 00:00:00 -to 00:00:00 -i " medium_name " -c:v libx264 -crf 20 -preset ultrafast " medium_name "_uf_trimmed-" k ".mp4
	
	--this assumes the first Cut is 1x
	
	if (k==1) then
		zstrtcp="00:00:00"
		zstrtc=string.sub(zstrtsp,1,8)
		ztms[k]="1x"
	else
		zstrtcp=zstrtc
		zstrtc=string.sub(zstrtsp,1,8)
		ztms[k]=string.sub(tostring(rawget(tmsorted,k-1)),10,12)
	end
	
	--this should add the final output string
	--to the entries list
	--zstrout=tostring("ffmpeg -y -ss "..tostring(zstrtcp).." -to "..tostring(zstrtc).." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast "..medium_name.."_uf_trimmed-"..tostring(k)..".mp4")
		
	--old working one
	--zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast "..zstrmed.."_uf_t-"..tostring(k)..".mp4")
	
	if (ztms[k]=="1x") then	
		zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast -r 60 "..zstrmed.."_uf_t_"..tostring(k).."_"..ztms[k]..".mp4")
		--zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -codec copy -preset ultrafast -r 60 "..zstrmed.."_uf_t_"..tostring(k).."_"..ztms[k]..".mp4")
	end
	
	if (ztms[k]=="2x") then	
		zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast -r 60 -filter_complex \"[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]\" -map \"[v]\" -map \"[a]\" "..zstrmed.."_uf_t_"..tostring(k).."_"..ztms[k]..".mp4")
	end
	
	if (ztms[k]=="4x") then	
		zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast -r 60 -filter_complex \"[0:v]setpts=0.25*PTS[v];[0:a]atempo=4.0[a]\" -map \"[v]\" -map \"[a]\" "..zstrmed.."_uf_t_"..tostring(k).."_"..ztms[k]..".mp4")
	end
	
	if (ztms[k]=="8x") then	
		zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast -r 60 -filter_complex \"[0:v]setpts=0.125*PTS[v];[0:a]atempo=8.0[a]\" -map \"[v]\" -map \"[a]\" "..zstrmed.."_uf_t_"..tostring(k).."_"..ztms[k]..".mp4")
	end
	
	tms[k]=zstrout
	
	--ztms[k]=tostring(rawget(tmsorted,k))
	--zstrtc=string.sub(zstrtsp,1,8)
	--ztms[k]=string.sub(tostring(rawget(tmsorted,k)),10,12)
	
	end
	
	--this adds the last X from the list
	--because the first one gets replaced by 1x every time
	
		zstrtsp=tostring(rawget(tmsorted,k))
	zstrtcp=zstrtc
	--zstrtc=string.sub(zstrtsp,1,8)
	
	--used to assume 30 mins for last entry
	--zstrtc="00:30:00"
	
	--now it gets the file length
	zstrtc=getfilelength()
	
	k=k+1

	ztms[k]=string.sub(tostring(rawget(tmsorted,k-1)),10,12)
	
		if (ztms[k]=="1x") then	
		zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast -r 60 "..zstrmed.."_uf_t_"..tostring(k).."_"..ztms[k]..".mp4")
		--zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -codec copy -preset ultrafast -r 60 "..zstrmed.."_uf_t_"..tostring(k).."_"..ztms[k]..".mp4")
	end
	
	if (ztms[k]=="2x") then	
		zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast -r 60 -filter_complex \"[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]\" -map \"[v]\" -map \"[a]\" "..zstrmed.."_uf_t_"..tostring(k).."_"..ztms[k]..".mp4")
	end
	
	if (ztms[k]=="4x") then	
		zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast -r 60 -filter_complex \"[0:v]setpts=0.25*PTS[v];[0:a]atempo=4.0[a]\" -map \"[v]\" -map \"[a]\" "..zstrmed.."_uf_t_"..tostring(k).."_"..ztms[k]..".mp4")
	end
	
	if (ztms[k]=="8x") then	
		zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast -r 60 -filter_complex \"[0:v]setpts=0.125*PTS[v];[0:a]atempo=8.0[a]\" -map \"[v]\" -map \"[a]\" "..zstrmed.."_uf_t_"..tostring(k).."_"..ztms[k]..".mp4")
	end
	
	tms[k]=zstrout

	--fixed
	--this adds an extra line for the end of the file
	--from the last Cut
	--still need to add the code that gets the length of the file
	--for now i just have to manually add it
	
	--[[
	k=k+1
	zstrtcp=zstrtc
	--zstrtc="00:00:00"
	zstrtc="00:30:00"

	--zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast "..zstrmed.."_uf_t-"..tostring(k)..".mp4")
	
	zstrout=tostring("ffmpeg -y -ss "..zstrtcp.." -to "..zstrtc.." -i "..medium_name.." -c:v libx264 -crf 20 -preset ultrafast -r 60 "..zstrmed.."_uf_t_"..tostring(k).."_XX.mp4")
	
	tms[k]=zstrout
	ztms[k]="XX"
]]

	--this looks like the playlist thing
	--im going to comment it out
	--seems to work with it commented out
	--the gui just leaves the play list
	
	--[[if check_xspf then
		doxspf=check_xspf:get_checked()
		main_layout:del_widget(check_xspf)
		check_xspf=nil
	end
	]]
	
	--this deletes the export button
	--trying to comment it out to see what it does
	--it works
	--main_layout:del_widget(imp_button)
	--imp_button=nil
	
	printd=true
	if not(doxspf) then
		dest=vlc.config.userdatadir().."/Memos.txt"
		--dest="d:\vc\zffm2.bat"
	
	--io.open(filename,"w"):close()
	--file=io.open(dest,"w")
	--file=io.close()
	
	--file=io.open(dest,"a+")
	--w+ should overwrite the file
	file=io.open(dest,"w+")
		--file:write(os.date("%Y/%m/%d %H:%M").."\n")
		--file:write(medium_name.."\n")

		--file:write("rem "..os.date("%Y/%m/%d %H:%M").."\n")
		--file:write("rem "..medium_name.."\n")
	--file:write("================\n")

		k=0
		while k<(znmstart+1) do
			k=k+1
			file:write(tms[k].."\n")
		end
	
	--this prints the speed order 1x 2x etc
	--for debugging
	--file:write("rem ================\n")
	
	--this is for getting the file length test
	--it works, kind of
	
	--local zfl
	--zfl=getfilelength()
	--file:write(zfl.."\n")
	
	--[[
	k=0
		while k<(znmstart+1) do
			k=k+1
			file:write("rem "..ztms[k].."\n")
		end
	]]
	
		--[[
	if minsec_display>0 then
			file:write(formatpos(1).." - THE END -\n")
		else
			file:write("1000 - THE END -\n")
		end
		file:write("================\n")
		]]
	file:flush()
		file:close()
		return
	end
	if string.find(medium_uri,"<") or string.find(medium_uri,"&") then	-- playlist killers
		return
	end
	
	--removing playlist stuff
	--[[
	dest=vlc.config.userdatadir().."/Memos.xspf"

	-- Step 1 : start with existing playlist or root structure
	local filex=io.open(dest,"r+")
	if filex then
		filex:seek("end",-13)	-- </playlist>
	else
		filex=io.open(dest,"w+")
		filex:write('<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<playlist xmlns=\"http://xspf.org/ns/0/\" ')
		filex:write('xmlns:vlc=\"http://www.videolan.org/vlc/playlist/ns/0/\" version=\"1\">\n')
		filex:write("<title>Cuttrak_playlist [started "..os.date("%Y/%m/%d %H:%M").."]</title>\n")
	end

	-- Step 2 : add new playlist
	filex:write("<trackList>\n")
	local kk,mtime
	local mame,chtime
	local chext='<extension application=\"http://www.videolan.org/vlc/playlist/0\">\n'
	if znmstart==0 then
			mame=string.gsub(medium_name,"<","_")
			mame=string.gsub(mame,"&","_")
			filex:write("<track>\n<title>"..mame.."</title>\n","<location>"..medium_uri.."</location>\n")
			filex:write(chext)
			filex:write("<vlc:id>0</vlc:id>\n<vlc:option>start-time=0</vlc:option>\n</extension>\n</track>\n")
	else
			kk=0
			k=0
			while kk<znmstart do
					kk=kk+1
					mame=string.sub(tms[kk],dectoCutname)
					if #(mame)>50 then mame=string.sub(mame,1,48)..".." end
					mame=string.gsub(mame,"<","_")
					mame=string.gsub(mame,"&","_")
					chtime=string.sub(tms[kk],1,(dectoCutname-1))
					if minsec_display>0 then
						if string.sub(chtime,1,1)==":" then
							mtime=math.floor(tdur)
						else
mtime=tonumber(string.sub(chtime,7,8))+60*tonumber(string.sub(chtime,4,5))+3600*tonumber(string.sub(chtime,1,2))
						end
					else
							mtime=math.floor(tdur/1000*tonumber(chtime))
					end
filex:write("<track>\n<title>"..mame.."</title>\n<location>"..medium_uri.."</location>\n")
filex:write(chext)
filex:write("<vlc:id>",k,"</vlc:id>\n<vlc:option>start-time=",mtime,"</vlc:option>\n</extension>\n</track>\n")
					k=k+1
			end
	end
	filex:write("</trackList>\n")
	filex:write(chext)
	mame=string.gsub(medium_name,"<","_")
	mame=string.gsub(mame,"&","_")
	filex:write('<vlc:node title=\"'..mame..'\">\n')
	if znmstart==0 then
			filex:write('<vlc:item tid=\"0\" />\n')
	else
			k=0
			while k<znmstart do
				filex:write('<vlc:item tid=\"',k,'\" />\n')
				k=k+1
			end
	end
	filex:write("</vlc:node>\n</extension> \n</playlist>\n")
	filex:flush()
	filex:close()
	]]
	--end of playlist stuff
end

function showkerr(ka)
	local chi
	afferr=true
	--if ka==7 then chi="<b><font color=darkred>One selection please !"
	if ka==7 then chi="<b><font color=red>One selection please !"
	else
		--chi="<b><font color=darkred>Naming rules : "
		chi="<b><font color=red> ka error "..ka.." - Naming rules: "
		if ka>1 then
			chi=chi.."NO *&"
		else
			chi=chi.."2 chars min, NO ~"
		end
	end
	chi=chi.."</font></b>"
	--err_label=main_layout:add_label(chi,1,2,3)
	err_label=main_layout:add_label(chi,1,11,4)
end

function zdurtostring(duration)
		return string.format("%02d:%02d:%02d",
	math.floor(duration/3600),
	math.floor(duration/60)%60,
	math.floor(duration%60))
end

function getfilelength()
	local zdur=vlc.input.item():duration()
	zdur=math.floor(zdur)
	local zdurstr
	zdurstr=zdurtostring(zdur)
	return zdurstr
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end