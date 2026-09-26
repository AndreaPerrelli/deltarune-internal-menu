using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Security.Cryptography;
using UndertaleModLib;
var path=Environment.GetEnvironmentVariable("IM_RELEASE_REPORT");
var json=JsonDocument.Parse(File.ReadAllText(path));
int count=json.RootElement.GetProperty("originalStringCount").GetInt32();
if(Data.Code.ByName("gml_GlobalScript_scr_im_menu")==null)throw new Exception("Missing menu code");
if(Data.Strings.Count<count)throw new Exception("Original string table truncated");
string hash=Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(Data.Strings.Take(count).Select(s=>s.Content).ToArray()))));
if(hash!=json.RootElement.GetProperty("originalStringsSHA256").GetString())throw new Exception("Original text verification failed");
File.WriteAllText(path+".verified","VERIFIED");


