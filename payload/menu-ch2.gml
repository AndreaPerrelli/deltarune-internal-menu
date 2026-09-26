function scr_im_init() {
    if (variable_global_exists("im")) return;
    global.im = {open:false, page:0, row:0, rows:[], title:"", note:"", frozen:[],
        god:false, ohk:false, tplock:false, tp:100, graze:1, speed:1, noclip:false,
        noenc:false, items:false, text:0, palette:0, sprite:-1, target:0,
        flag:0, undo:[], catalog:[], filtered:[], kind:"", query:"", searching:false,
        editing:false, numberkey:"", numbertitle:"", numbermin:0, numbermax:0,
        confirm:"", confirmvalue:0, music:-1, stream:-1, fake:0, clock:0,
        basefps:game_get_speed(gamespeed_fps), backroom:-1, backx:0, backy:0,
        warp_pending:false, warp_x:0, warp_y:0, roster:[1,2,3], maxchar:4};
    scr_im_catalog();
}
function scr_im_on(_key) {
    return variable_global_exists("im") && variable_struct_get(global.im, _key);
}
function scr_im_row(_label, _action) {
    array_push(global.im.rows, [_label, _action]);
}
function scr_im_bool(_b) { return _b ? "ON" : "OFF"; }
function scr_im_build() {
    var m = global.im;
    m.rows = [];
    if (m.page == 0) {
        m.title = "CHAPTER 2 / INTERNAL MOD MENU";
        scr_im_row("Combat & gameplay", "page1");
        scr_im_row("Inventory & party", "page2");
        scr_im_row("World & flags", "page3");
        scr_im_row("Audio, visuals & strange events", "page4");
        scr_im_row("Reset all toggles", "reset");
        scr_im_row("Return to game", "close");
    }
    if (m.page == 1) {
        m.title = "COMBAT & GAMEPLAY";
        scr_im_row("God mode: " + scr_im_bool(m.god), "god");
        scr_im_row("One-hit kills: " + scr_im_bool(m.ohk), "ohk");
        scr_im_row("Lock TP: " + scr_im_bool(m.tplock), "tplock");
        scr_im_row("TP target: " + string(m.tp) + "%", "tp");
        scr_im_row("Fill TP now", "fill");
        scr_im_row("Graze TP multiplier: " + string(m.graze) + "x", "graze");
        scr_im_row("Game speed: " + string(m.speed) + "x", "speed");
        scr_im_row("Block encounter starts: " + scr_im_bool(m.noenc), "noenc");
        scr_im_row("Force encounter / replay [experimental]", "listencounter");
        scr_im_row("Defeat current enemies", "clear");
    }
    if (m.page == 2) {
        m.title = "INVENTORY & PARTY";
        scr_im_row("Spawn consumable / debug item", "listitem");
        scr_im_row("Spawn weapon", "listweapon");
        scr_im_row("Spawn armor", "listarmor");
        scr_im_row("Spawn key item", "listkey");
        scr_im_row("D$ wallet: " + string(global.gold), "gold");
        scr_im_row("Infinite consumables: " + scr_im_bool(m.items), "items");
        scr_im_row("Party: Kris / Susie / Ralsei", "party0");
        scr_im_row("Party: Kris / Susie / Noelle [experimental]", "party1");
        scr_im_row("Party: Kris / Ralsei / Noelle [experimental]", "party2");
        scr_im_row("Party: Kris solo", "party3");
        scr_im_row("Custom battle roster [experimental]", "customparty");
    }
    if (m.page == 3) {
        m.title = "WORLD & FLAGS / EXPERIMENTAL";
        scr_im_row("No-clip: " + scr_im_bool(m.noclip), "noclip");
        scr_im_row("Warp to room (all compiled rooms)", "listroom");
        scr_im_row("Return to previous room", "returnroom");
        scr_im_row("FLAG index: " + string(m.flag), "flagindex");
        scr_im_row("FLAG value: " + string(global.flag[m.flag]), "flagvalue");
        scr_im_row("Undo last FLAG edit", "undo");
        scr_im_row("Release overworld movement lock", "unlock");
    }
    if (m.page == 4) {
        m.title = "AUDIO, VISUALS & STRANGE EVENTS";
        scr_im_row("Jukebox: music files", "listmusic");
        scr_im_row("Sound test: compiled sounds", "listsound");
        scr_im_row("Stop jukebox / restore game music", "stopmusic");
        var targets=["Kris", "Susie", "Ralsei", "Noelle"];
        var palettes=["Original", "Cyan", "Violet", "Gold", "Red"];
        scr_im_row("Visual target: " + targets[m.target], "target");
        scr_im_row("Palette tint: " + palettes[m.palette], "palette");
        scr_im_row("Overworld sprite browser", "listsprite");
        scr_im_row("Restore original sprites", "restoresprite");
        var texts=["Normal", "Instant text", "Auto advance"];
        scr_im_row("Dialogue: " + texts[m.text], "text");
        scr_im_row("Fake Gaster / error screen (visual only)", "fake");
    }
    if (m.page == 5) {
        m.title = string_upper(m.kind) + " BROWSER";
        for (var i = 0; i < array_length(m.filtered); i++) {
            var e = m.catalog[m.filtered[i]];
            scr_im_row(string(e[0]) + "  " + e[1], "choose");
        }
        if (array_length(m.rows) == 0) scr_im_row("No matching assets", "none");
    }
    if(m.page==6) {
        m.title="CUSTOM PARTY / EXPERIMENTAL";
        var names=["Empty","Kris","Susie","Ralsei","Noelle"];
        for(var j=0;j<3;j++) scr_im_row("Slot "+string(j+1)+": "+names[m.roster[j]],"slot"+string(j));
        scr_im_row("Apply roster", "applyparty");
    }
    m.row = clamp(m.row, 0, max(0, array_length(m.rows)-1));
}
function scr_im_open() {
    var m = global.im;
    m.frozen = [];
    for (var i = 0; i < instance_count; i++) {
        var inst = instance_id_get(i);
        if (inst != id) array_push(m.frozen, inst);
    }
    for (var i = 0; i < array_length(m.frozen); i++) instance_deactivate_object(m.frozen[i]);
    m.open = true;
    m.note = "F1 closes. Changes to inventory and flags can enter saves.";
    game_set_speed(m.basefps, gamespeed_fps);
    scr_im_build();
}
function scr_im_close() {
    var m = global.im;
    for (var i = 0; i < array_length(m.frozen); i++) instance_activate_object(m.frozen[i]);
    m.frozen = [];
    m.open = false; m.editing = false; m.searching = false; m.confirm = ""; m.fake = 0;
    keyboard_clear(vk_enter); keyboard_clear(vk_escape);
    keyboard_clear(vk_up); keyboard_clear(vk_down); keyboard_clear(vk_left); keyboard_clear(vk_right);
    game_set_speed(m.basefps * m.speed, gamespeed_fps);
}
function scr_im_filter() {
    var m = global.im; m.filtered = [];
    for (var i = 0; i < array_length(m.catalog); i++) {
        var e = m.catalog[i];
        if (m.query == "" || string_pos(string_lower(m.query), string_lower(string(e[0]) + " " + e[1])) > 0) array_push(m.filtered, i);
    }
    m.row = 0; scr_im_build();
}
function scr_im_list(_kind) {
    var m = global.im;
    m.kind = _kind; m.catalog = variable_struct_get(m, "cat_" + _kind);
    m.page = 5; m.query = ""; scr_im_filter();
    m.note = "Up/Down select; PgUp/PgDn jump; S search; Enter apply.";
}
function scr_im_number(_key, _title, _value, _min, _max) {
    var m = global.im;
    m.editing = true; m.numberkey = _key; m.numbertitle = _title;
    m.numbermin = _min; m.numbermax = _max; keyboard_string = string(_value);
}
function scr_im_stopmusic() {
    var m = global.im;
    if (m.music != -1) audio_stop_sound(m.music);
    if (m.stream != -1) audio_destroy_stream(m.stream);
    m.music = -1; m.stream = -1;
    audio_resume_all();
}
function scr_im_apply(_kind, _value) {
    var m = global.im;
    scr_im_close();
    if (_kind == "room") {
        if (instance_exists(obj_battlecontroller) || instance_exists(obj_encounterbasic)) { m.warp_pending=false; scr_im_open(); m.note = "Finish the battle before warping."; return; }
        m.backroom = room;
        if (instance_exists(obj_mainchara)) { m.backx = obj_mainchara.x; m.backy = obj_mainchara.y; }
        room_goto(_value); return;
    }
    if (_kind == "encounter") {
        if (!instance_exists(obj_mainchara) || global.interact != 0 || instance_exists(obj_battlecontroller) || instance_exists(obj_encounterbasic)) {
            scr_im_open(); m.note = "Start encounters from a free-roaming overworld scene."; return;
        }
        if(global.chapter==3 && _value==121 && (global.char[0]!=1 || global.char[1]!=2 || global.char[2]!=3)) {
            scr_im_open();m.note="Tenna requires the Kris / Susie / Ralsei party.";return;
        }
        var old = m.noenc; m.noenc = false;
        scr_im_startbattle(_value);
        m.noenc = old; return;
    }
    if (_kind == "item" || _kind == "weapon" || _kind == "armor" || _kind == "key") {
        scr_im_give(_value, _kind);
        var failed = noroom;
        scr_im_open(); m.note = failed ? "Inventory full; nothing added." : "Added to inventory."; return;
    }
    if (_kind == "music" || _kind == "sound") {
        scr_im_stopmusic(); audio_pause_all();
        if (_kind == "music") {
            m.stream = audio_create_stream(working_directory + "../mus/" + _value);
            if (m.stream != -1) m.music = audio_play_sound(m.stream, 100, true);
        } else m.music = audio_play_sound(_value, 100, false);
        if (m.music == -1) audio_resume_all();
        scr_im_open(); m.note = m.music!=-1 ? "Jukebox active; Stop restores game audio." : "Audio could not be opened; game audio restored."; return;
    }
    if (_kind == "sprite") { m.sprite = _value; scr_im_open(); m.note = "Sprite override applies while exploring."; return; }
}
function scr_im_action(_a, _delta) {
    var m = global.im;
    if (string_copy(_a,1,4) == "page") { m.page = real(string_copy(_a,5,1)); m.row = 0; m.note = "Enter toggles/edits. Left/Right adjusts values."; }
    else if (string_copy(_a,1,4) == "list") { scr_im_list(string_delete(_a,1,4)); return; }
    else if (_a == "god" || _a == "ohk" || _a == "tplock" || _a == "items" || _a == "noenc" || _a == "noclip") variable_struct_set(m, _a, !variable_struct_get(m, _a));
    else if (_a == "speed") { if (_delta) m.speed = clamp(m.speed + _delta * 0.25,0.5,4); else scr_im_number("speed","Game speed (0.5 - 4.0)",m.speed,0.5,4); }
    else if (_a == "graze") { if (_delta) m.graze = clamp(m.graze + _delta,0,100); else scr_im_number("graze","Graze TP multiplier",m.graze,0,100); }
    else if (_a == "tp") { if (_delta) m.tp = clamp(m.tp + _delta*5,0,100); else scr_im_number("tp","TP percentage",m.tp,0,100); }
    else if (_a == "fill") { global.tension = global.maxtension * m.tp/100; m.note = "TP filled to target."; }
    else if (_a == "gold") scr_im_number("gold","D$ wallet",global.gold,0,9999999);
    else if (_a == "flagindex") scr_im_number("flagindex","FLAG index",m.flag,0,array_length(global.flag)-1);
    else if (_a == "flagvalue") scr_im_number("flagvalue","FLAG["+string(m.flag)+"] new value",global.flag[m.flag],-9999999,9999999);
    else if (_a == "customparty") { m.roster=[global.char[0],global.char[1],global.char[2]];m.page=6;m.row=0;m.note="Overworld lead remains Kris; combat uses this roster."; }
    else if(string_copy(_a,1,4)=="slot") {
        var slot=real(string_copy(_a,5,1));m.roster[slot]=(m.roster[slot]+(_delta<0?m.maxchar:1)) mod (m.maxchar+1);
    }
    else if(_a=="applyparty") {
        var a=m.roster;
        if(a[0]==0 || (a[1]==0 && a[2]!=0) || a[0]==a[1] || a[0]==a[2] || (a[1]!=0 && a[1]==a[2])) {m.note="Use unique characters, with empty slots at the end.";return;}
        scr_im_close();
        if(global.interact!=0 || !instance_exists(obj_mainchara) || instance_exists(obj_battlecontroller)) {scr_im_open();m.note="Apply a roster while freely exploring the overworld.";return;}
        scr_im_setparty(false,false,false);global.char[0]=0;scr_getchar(a[0]);
        for(var j=1;j<3;j++) if(a[j]!=0) {scr_getchar(a[j]);scr_makecaterpillar(obj_mainchara.x,obj_mainchara.y,a[j],j-1);}
        scr_im_open();m.note="Custom roster applied. Story scripts may overwrite it.";
    }
    else if (_a == "undo") {
        if (array_length(m.undo)>0) { var u = array_pop(m.undo); global.flag[u[0]]=u[1]; m.flag=u[0]; m.note="FLAG edit undone."; }
    }
    else if (_a == "choose" && array_length(m.filtered)>0) {
        var e = m.catalog[m.filtered[m.row]];
        if (m.kind == "room" || m.kind == "encounter") { m.confirm=m.kind; m.confirmvalue=e[0]; m.note="Experimental: story prerequisites may be missing."; }
        else scr_im_apply(m.kind,e[0]);
    }
    else if (_a == "returnroom" && m.backroom >= 0) { m.warp_x=m.backx; m.warp_y=m.backy; m.warp_pending=true; m.confirm="room"; m.confirmvalue=m.backroom; }
    else if (_a == "clear") {
        scr_im_close();
        if (instance_exists(obj_battlecontroller)) {
            for (var j=0;j<3;j++) if (instance_exists(global.monsterinstance[j]) && global.monsterhp[j]>0) {
                global.monsterhp[j]=0; with(global.monsterinstance[j]) scr_monsterdefeat();
            }
        }
        return;
    }
    else if (string_copy(_a,1,5)=="party") {
        scr_im_close();
        if (global.interact != 0 || instance_exists(obj_battlecontroller)) { scr_im_open(); m.note="Change party during free overworld movement."; return; }
        var p=real(string_copy(_a,6,1));
        global.char[0]=1;
        scr_im_setparty(p==0 || p==1,p==0 || p==2,p==1 || p==2);
        scr_im_open(); m.note="Party updated; story scripts may change it later.";
    }
    else if (_a == "unlock") { global.interact=0; m.note="Movement released. Story scene may still be running."; }
    else if (_a == "target") { m.target=(m.target+1) mod m.maxchar; }
    else if (_a == "palette") m.palette=(m.palette+1) mod 5;
    else if (_a == "restoresprite") { m.sprite=-1; m.palette=0; }
    else if (_a == "text") m.text=(m.text+1) mod 3;
    else if (_a == "stopmusic") scr_im_stopmusic();
    else if (_a == "fake") { m.fake=1; m.clock=0; var s=asset_get_index("snd_him_quick"); if(s==-1)s=asset_get_index("snd_hypnosis"); if(s==-1)s=asset_get_index("snd_noise"); if(s!=-1) audio_play_sound(s,100,false); }
    else if (_a == "reset") {
        m.god=false; m.ohk=false; m.tplock=false; m.items=false; m.noenc=false; m.noclip=false;
        m.tp=100; m.graze=1; m.speed=1; m.text=0; m.palette=0; m.sprite=-1; scr_im_stopmusic();
        m.note="Toggles reset. Inventory, flags and room changes are retained.";
    }
    else if (_a == "close") { scr_im_close(); return; }
    scr_im_build();
}
function scr_im_tick() {
    scr_im_init(); var m=global.im; m.clock++;
    if (keyboard_check_pressed(vk_f1)) { if(m.open) scr_im_close(); else scr_im_open(); return; }
    if (!m.open) {
        if(m.speed!=1 && game_get_speed(gamespeed_fps)!=m.basefps*m.speed) game_set_speed(m.basefps*m.speed,gamespeed_fps);
        if(m.tplock && variable_global_exists("maxtension")) global.tension=global.maxtension*m.tp/100;
        if(m.warp_pending && room!=m.backroom && instance_exists(obj_mainchara)) {
            obj_mainchara.x=m.warp_x;obj_mainchara.y=m.warp_y;m.warp_pending=false;
        }
        return;
    }
    if (m.fake) { if(keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter)) m.fake=0; return; }
    if (m.confirm != "") {
        if(keyboard_check_pressed(vk_escape)) {m.confirm="";m.warp_pending=false;}
        else if(keyboard_check_pressed(vk_enter)) { var k=m.confirm; var v=m.confirmvalue; m.confirm=""; scr_im_apply(k,v); }
        return;
    }
    if (m.editing) {
        if(keyboard_check_pressed(vk_delete)) keyboard_string="";
        if(keyboard_check_pressed(vk_escape)) m.editing=false;
        else if(keyboard_check_pressed(vk_enter)) {
            var str=keyboard_string; var valid=string_length(str)>0; var dots=0; var digits=0;
            for(var i=1;i<=string_length(str);i++) { var ch=string_char_at(str,i); if(ch==".") dots++; else if(ch=="-" && i==1) {} else if(string_pos(ch,"0123456789")>0) digits++; else valid=false; }
            if(dots>1 || digits==0) valid=false;
            if(valid) {
                var v=clamp(real(str),m.numbermin,m.numbermax);
                if(m.numberkey=="gold") global.gold=floor(v);
                else if(m.numberkey=="flagindex") m.flag=floor(v);
                else if(m.numberkey=="flagvalue") { array_push(m.undo,[m.flag,global.flag[m.flag]]); global.flag[m.flag]=v; }
                else variable_struct_set(m,m.numberkey,v);
                m.editing=false; scr_im_build();
            } else m.note="Enter a valid number.";
        }
        return;
    }
    if (m.searching) {
        m.query=keyboard_string; scr_im_filter();
        if(keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) m.searching=false;
        return;
    }
    if(keyboard_check_pressed(vk_escape)) { if(m.page==0) scr_im_close(); else {m.page=0;m.row=0;scr_im_build();} return; }
    if(m.page==5 && keyboard_check_pressed(ord("S"))) { keyboard_string="";m.searching=true;return; }
    var d=keyboard_check_pressed(vk_down)-keyboard_check_pressed(vk_up);
    d+=10*(keyboard_check_pressed(vk_pagedown)-keyboard_check_pressed(vk_pageup));
    m.row=clamp(m.row+d,0,array_length(m.rows)-1);
    var delta=keyboard_check_pressed(vk_right)-keyboard_check_pressed(vk_left);
    if(m.page==1 && mouse_check_button(mb_left)) {
        var mx=device_mouse_x_to_gui(0);var my=device_mouse_y_to_gui(0);
        if(mx>=385 && mx<=594 && my>=91+6*27 && my<=91+7*27) {
            m.speed=clamp(round((0.5+(mx-385)/209*3.5)*20)/20,0.5,4);
            m.row=6;scr_im_build();
        }
    }
    if(keyboard_check_pressed(vk_enter) || delta) scr_im_action(m.rows[m.row][1],delta);
}
function scr_im_draw() {
    if(!variable_global_exists("im")) return;
    var m=global.im;
    var oldfont=draw_get_font(); var oldcolor=draw_get_color(); var oldalpha=draw_get_alpha();
    var oldh=draw_get_halign(); var oldv=draw_get_valign();
    draw_set_font(fnt_main);draw_set_alpha(1);draw_set_halign(fa_left);draw_set_valign(fa_top);
    if(m.open) {
        draw_set_color(make_color_rgb(9,12,22));draw_rectangle(0,0,640,480,false);
        draw_set_color(make_color_rgb(87,222,209));draw_rectangle(16,14,624,17,false);
        draw_text_transformed(24,26,m.title,1.3,1.3,0);
        draw_set_color(c_gray);draw_text_transformed(24,57,"PAUSED  /  F1 close  /  Esc back  /  Enter select",1,1,0);
        var start=max(0,m.row-9);
        for(var i=start;i<min(start+11,array_length(m.rows));i++) {
            var yy=91+(i-start)*27;
            if(i==m.row) {draw_set_color(make_color_rgb(27,58,66));draw_rectangle(18,yy-2,621,yy+24,false);}
            draw_set_color(i==m.row?c_yellow:c_white);
            draw_text_transformed(26,yy,(i==m.row?"> ":"  ")+string_copy(m.rows[i][0],1,75),1,1,0);
            if(m.page==1 && i==6) {
                draw_set_color(c_gray);draw_rectangle(385,yy+10,594,yy+13,false);
                var sx=385+(m.speed-0.5)/3.5*209;
                draw_set_color(c_aqua);draw_rectangle(sx-3,yy+5,sx+3,yy+18,false);
            }
        }
        draw_set_color(c_gray);draw_text_transformed(24,400,string(m.row+1)+" / "+string(array_length(m.rows))+(m.page==5?"    Search: "+m.query:""),1,1,0);
        draw_set_color(c_white);draw_text_transformed(24,427,string_copy(m.note,1,83),1,1,0);
        if(m.searching || m.editing || m.confirm!="") {
            draw_set_color(make_color_rgb(17,23,39));draw_rectangle(28,157,612,316,false);
            draw_set_color(c_aqua);draw_rectangle(28,157,612,316,true);
            var title=m.searching?"SEARCH ASSETS":(m.editing?m.numbertitle:"EXPERIMENTAL TRANSITION");
            draw_set_color(c_white);draw_text_transformed(45,175,title,1.2,1.2,0);
            draw_text_transformed(45,215,m.confirm!=""?"Missing story setup can break this scene.":string_copy(keyboard_string,1,65)+"_",1,1,0);
            draw_text_transformed(45,275,"Enter: apply    Esc: cancel    Del: clear",1,1,0);
        }
        if(m.fake) {
            draw_set_color(c_black);draw_rectangle(0,0,640,480,false);
            draw_set_color((m.clock mod 12)<3?c_red:c_white);
            draw_text_transformed(64,120,"CONNECTION INTERRUPTED",1.5,1.5,0);
            draw_text_transformed(64,200,"SAVE DATA: [REDACTED]",1.4,1.4,0);
            draw_text_transformed(64,260,"ARE YOU STILL THERE?",1.4,1.4,0);
            draw_set_color(c_gray);draw_text_transformed(64,390,"SIMULATED EVENT - no files were changed.",1,1,0);
            draw_text_transformed(64,422,"Enter / Esc to dismiss",1,1,0);
        }
    } else {
        draw_set_color(c_aqua);draw_text_transformed(8,462,"F1 MOD MENU",0.85,0.85,0);
    }
    draw_set_font(oldfont);draw_set_color(oldcolor);draw_set_alpha(oldalpha);draw_set_halign(oldh);draw_set_valign(oldv);
}
function scr_im_visual(_who) {
    if(!variable_global_exists("im")) return;
    var m=global.im;
    if(m.target != _who) return;
    var colors=[c_white,c_aqua,make_color_rgb(190,110,255),c_yellow,c_red];
    if(m.palette>0) image_blend=colors[m.palette];
    if(m.sprite>=0 && sprite_exists(m.sprite)) sprite_index=m.sprite;
}


