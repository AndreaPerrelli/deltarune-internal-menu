using System;
using System.IO;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Security.Cryptography;
using UndertaleModLib.Decompiler;
using UndertaleModLib.Compiler;
using UndertaleModLib.Models;
using UndertaleModLib;
int chapter=int.Parse(Environment.GetEnvironmentVariable("IM_RELEASE_CHAPTER"));
string payload=Environment.GetEnvironmentVariable("IM_RELEASE_PAYLOAD")??throw new Exception("Use Install.ps1 to run this patch.");
string reportPath=Environment.GetEnvironmentVariable("IM_RELEASE_REPORT")??throw new Exception("Missing report path");
if(chapter<1||chapter>5)throw new Exception("Unsupported chapter");
if(Data.Code.ByName("gml_GlobalScript_scr_im_menu")!=null || Data.Functions.ByName("scr_im_init")!=null)
 throw new Exception("The internal menu is already present. Restore its pre-installation backup first; do not apply twice.");
var context=new GlobalDecompileContext(Data);
var originalCode=new Dictionary<string,string>();
var preservedStrings=Data.Strings.Select(s=>s.Content).ToArray();
var group=new CodeImportGroup(Data){AutoCreateAssets=true,MainThreadAction=MainThreadAction};
var changed=new Dictionary<string,string>();
var report=new List<string>();
bool Has(string n)=>Data.Code.ByName(n)!=null;
string Read(string n) { if(changed.ContainsKey(n))return changed[n]; if(!originalCode.ContainsKey(n)){var code=Data.Code.ByName(n)??throw new Exception("Missing code: "+n);originalCode[n]=new Underanalyzer.Decompiler.DecompileContext(context,code,Data.ToolInfo.DecompilerSettings).DecompileToString();}return originalCode[n];}
void Set(string n,string s){changed[n]=s;}
void Replace(string n,string a,string b,bool required=true){
 if(!Has(n)||!Read(n).Contains(a)){if(required)throw new Exception("Missing anchor: "+n+" / "+a);report.Add("Not applicable: "+n+" / "+a);return;}
 Set(n,Read(n).Replace(a,b));
}
void Guard(string fn,string code,bool required=false){string n="gml_GlobalScript_"+fn;if(!Has(n)){if(required)throw new Exception(n);return;}var s=Read(n);Set(n,s.Insert(s.IndexOf('{')+1,"\n"+code+"\n"));}
var detected=Regex.Match(Read("gml_GlobalScript_scr_gamestart"),@"global\.chapter\s*=\s*(\d+)\s*;");
if(!detected.Success || int.Parse(detected.Groups[1].Value)!=chapter)throw new Exception("Archive chapter does not match the selected folder");
if(chapter!=1 && Data.GameObjects.ByName("obj_heronoelle")==null)throw new Exception("This build lacks the expected party assets; unsupported game version");
string Q(string value)=>JsonSerializer.Serialize(value);
var counts=new Dictionary<string,int>();
string BuildCatalog(){
 var b=new StringBuilder("function scr_im_catalog(){var m=global.im;\n");
 void Add(string kind,IEnumerable<string> entries){var list=entries.ToArray();counts[kind]=list.Length;b.Append("m.cat_").Append(kind).Append("=[").Append(string.Join(",",list)).Append("];\n");}
 Add("room",Data.Rooms.Select((r,i)=>"["+i+","+Q(r.Name.Content)+"]"));
 Add("sprite",Data.Sprites.Select((r,i)=>"["+i+","+Q(r.Name.Content)+"]"));
 Add("sound",Data.Sounds.Select((r,i)=>"["+i+","+Q(r.Name.Content)+"]"));
 string music=Environment.GetEnvironmentVariable("IM_RELEASE_MUSIC");
 if(string.IsNullOrEmpty(music)||!Directory.Exists(music))throw new Exception("Cannot find this installation's mus folder");
 Add("music",Directory.GetFiles(music,"*.ogg").OrderBy(p=>p,StringComparer.OrdinalIgnoreCase).Select(p=>"["+Q(Path.GetFileName(p))+","+Q(Path.GetFileNameWithoutExtension(p))+"]"));
 foreach(string kind in new[]{"item","weapon","armor","key"}){
  string src=Read("gml_GlobalScript_scr_"+(kind=="key"?"keyitem":kind)+"info");
  var entries=new List<string>();var ids=new HashSet<int>();
  foreach(Match m in Regex.Matches(src,@"(?s)        case (\d+):\s*(.*?)(?=\n        case |\n        default:|\z)")){
   int id=int.Parse(m.Groups[1].Value);if(id==0||!ids.Add(id))continue;
   var label=Regex.Match(m.Groups[2].Value,@"(?:itemnameb|weaponnametemp|armornametemp|tempkeyitemname)\s*=\s*([^;]+);");
   string expression=label.Success?label.Groups[1].Value.Trim():"";
   string quoted="\"(?:[^\"\\\\]|\\\\.)*\"";
   bool safe=Regex.IsMatch(expression,"^"+quoted+"$") || Regex.IsMatch(expression,"^(?:stringsetloc|scr_84_get_lang_string)\\("+quoted+"(?:,\\s*"+quoted+")?\\)$");
   if(!safe)expression=Q(kind+" "+id);
   entries.Add("["+id+","+expression+"]");
  }
  if(entries.Count==0)throw new Exception("No recognized "+kind+" IDs in this build");Add(kind,entries);
 }
 var encounters=new List<string>();
 foreach(Match m in Regex.Matches(Read("gml_GlobalScript_scr_encountersetup"),@"(?s)        case (\d+):\s*(.*?)(?=\n        case |\n        default:|\z)")){
  int id=int.Parse(m.Groups[1].Value);if(id==0)continue;
  var enemies=Regex.Matches(m.Groups[2].Value,@"global\.monsterinstancetype\[\d\] = (obj_[^;]+);").Cast<Match>().Select(v=>v.Groups[1].Value).Distinct().ToArray();
  if(enemies.Length==0||enemies.Any(e=>Data.GameObjects.ByName(e)==null))continue;
  string name=string.Join(" + ",enemies.Select(e=>e.Substring(4).Replace("_enemy","").Replace("_"," ")));
  if(enemies.Contains("obj_joker"))name="Jevil (joker)";
  if(enemies.Contains("obj_spamton_neo_enemy"))name="Spamton NEO";
  encounters.Add("["+id+","+Q(name)+"]");
 }
 if(encounters.Count==0)throw new Exception("No supported encounters");Add("encounter",encounters);
 b.Append("}");return b.ToString();
}
group.QueueReplace("gml_GlobalScript_scr_im_menu",File.ReadAllText(Path.Combine(payload,"menu-ch"+chapter+".gml"))+(chapter==3 ? "" : "\n"+File.ReadAllText(Path.Combine(payload,"compat-ch"+chapter+".gml"))));
group.QueueReplace("gml_GlobalScript_scr_im_catalog",BuildCatalog());
Set("gml_Object_obj_time_Create_0",Read("gml_Object_obj_time_Create_0")+"\nscr_im_init();");
Set("gml_Object_obj_time_Step_1","scr_im_tick();\nif(global.im.open) exit;\n"+Read("gml_Object_obj_time_Step_1"));
if(Has("gml_Object_obj_time_Step_0"))Set("gml_Object_obj_time_Step_0","if(scr_im_on(\"open\")) exit;\n"+Read("gml_Object_obj_time_Step_0"));
group.QueueAppend(Data.GameObjects.ByName("obj_time").EventHandlerFor(EventType.Draw,EventSubtypeDraw.DrawGUIEnd,Data),"\nscr_im_draw();");
foreach(string fn in new[]{"scr_damage","scr_damage_fixed","scr_damage_proportional","scr_damage_maxhp","scr_damage_sneo_final_attack","scr_damage_all_overworld"})Guard(fn,"if(scr_im_on(\"god\")) return;",fn=="scr_damage");
Guard("scr_damage_enemy","if(scr_im_on(\"ohk\") && arg1>0) arg1=max(arg1,global.monsterhp[arg0]+1);",true);
string graze="gml_Object_obj_grazebox_Collision_obj_collidebullet";
if(chapter==1){Replace(graze,"scr_tensionheal(grazepoints / 20);","scr_tensionheal((grazepoints / 20) * (variable_global_exists(\"im\") ? global.im.graze : 1));");Replace(graze,"scr_tensionheal(grazepoints);","scr_tensionheal(grazepoints * (variable_global_exists(\"im\") ? global.im.graze : 1));");}
else Replace(graze,"var _grazetpfactor = grazetpfactor;","var _grazetpfactor = grazetpfactor * (variable_global_exists(\"im\") ? global.im.graze : 1);");
if(chapter==1){
 Set("gml_Object_obj_testoverworldenemy_Step_0","if(scr_im_on(\"noenc\")) exit;\n"+Read("gml_Object_obj_testoverworldenemy_Step_0"));
 // Collision is intercepted before optional field enemies start their animation.
 foreach(string n in new[]{"gml_Object_obj_chaseenemy_Collision_obj_mainchara","gml_Object_obj_testoverworldenemy_Collision_obj_mainchara"})if(Has(n))Set(n,"if(scr_im_on(\"noenc\")) exit;\n"+Read(n));
}else Guard("scr_battle","if(scr_im_on(\"noenc\")) return;",true);
string move="gml_Object_obj_mainchara_Step_0";
if(chapter<=2)Replace(move,"place_meeting(","scr_im_wall(");
else Replace(move,"scr_debug() && noclip","((scr_debug() && noclip) || scr_im_on(\"noclip\"))");
if(chapter==3){
 Replace("gml_Object_obj_mainchara_board_Step_0","var checkcol = true;","var checkcol = !scr_im_on(\"noclip\");");
 Replace("gml_GlobalScript_scr_battle","else if (global.monstertype[other.__ien] == 104)","else if (global.monstertype[other.__ien] == 104 && i_ex(obj_ch3_PTB02_roaringknight))");
}
string dark="gml_Object_obj_darkcontroller_Step_0";
if(chapter==1){
 var s=Read(dark);int count=0;s=Regex.Replace(s,@"if \(usable == 1\)(\s*\{\s*)scr_itemshift",m=>{count++;return "if (usable == 1 && !scr_im_on(\"items\"))"+m.Groups[1].Value+"scr_itemshift";});if(count!=2)throw new Exception("Expected two overworld consumption hooks");Set(dark,s);
 Replace("gml_GlobalScript_scr_itemconsumeb","if (usable == 1)","if (usable == 1 && !scr_im_on(\"items\"))");
}else{
 foreach(string n in new[]{dark,"gml_GlobalScript_scr_itemconsumeb"}){
 Replace(n,"usable == 1 && replaceable == 0","usable == 1 && replaceable == 0 && !scr_im_on(\"items\")");
 Replace(n,"else if (replaceable > 0)","else if (replaceable > 0 && !scr_im_on(\"items\"))");
 }
}
Replace("gml_Object_obj_battlecontroller_Step_0","scr_itemshift_temp(global.bmenucoord[4][global.charturn], global.charturn);","if(!scr_im_on(\"items\")) scr_itemshift_temp(global.bmenucoord[4][global.charturn], global.charturn);",false);
Replace("gml_GlobalScript_scr_spelltext","scr_itemshift(global.bmenucoord[4][arg1], 0);","if(!scr_im_on(\"items\")) scr_itemshift(global.bmenucoord[4][arg1], 0);",false);
string textHook="if(variable_global_exists(\"im\") && !global.im.open){if(global.im.text>0)button2=1;if(global.im.text==2 && (global.im.clock mod 8)==0)button1=1;}\n";
Replace("gml_Object_obj_writer_Draw_0","if (dialoguer == 1 && formatted == 0)",textHook+"if (dialoguer == 1 && formatted == 0)");
string Wrap(string s,string who)=>"var _imSprite=sprite_index;var _imBlend=image_blend;scr_im_visual("+who+");\n"+s+"\nsprite_index=_imSprite;image_blend=_imBlend;";
Set("gml_Object_obj_mainchara_Draw_0",Wrap(Read("gml_Object_obj_mainchara_Draw_0"),"0"));
string who=chapter==1?"usprite==spr_ralseiu ? 2 : 1":"name==\"susie\" ? 1 : (name==\"ralsei\" ? 2 : 3)";
bool existingDraw=Has("gml_Object_obj_caterpillarchara_Draw_0");
var draw=Data.GameObjects.ByName("obj_caterpillarchara").EventHandlerFor(EventType.Draw,EventSubtypeDraw.Draw,Data);
string existing=existingDraw?Read(draw.Name.Content):"draw_self();";
group.QueueReplace(draw,Wrap(existing,who));
foreach(var kv in changed)group.QueueReplace(kv.Key,kv.Value);
group.Import();
for(int i=0;i<preservedStrings.Length;i++)if(Data.Strings[i].Content!=preservedStrings[i])throw new Exception("Original string table changed unexpectedly; refusing output");
string stringHash=Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(preservedStrings))));
File.WriteAllText(reportPath,JsonSerializer.Serialize(new{version="1.2.0",chapter,completed=true,originalStringsPreserved=true,originalStringCount=preservedStrings.Length,originalStringsSHA256=stringHash,counts,patchedEntries=changed.Keys.ToArray(),notes=report.ToArray()},new JsonSerializerOptions{WriteIndented=true}));


ScriptMessage("Chapter "+chapter+" internal menu compiled.");


