import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(ResumeRocketApp());

class ResumeRocketApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResumeRocket',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String,dynamic>> resumes = [];
  bool premium = false;

  @override
  void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('resumes') ?? '[]';
    setState((){ resumes = List<Map<String,dynamic>>.from(jsonDecode(raw)); premium = p.getBool('admin_premium') ?? false; });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('resumes', jsonEncode(resumes));
  }

  void _new() { resumes.insert(0, {'title':'Untitled','name':'','email':'','phone':'','summary':'','skills':'','experience':[], 'education':[], 'template':'ats_classic'}); _save(); setState((){}); }

  void _edit(int i) async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_)=>EditorScreen(data: resumes[i], premium: premium)));
    if(res!=null){ resumes[i]=res; _save(); setState((){}); }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('ResumeRocket'), actions: [IconButton(icon: Icon(Icons.admin_panel_settings), onPressed: () async { final p=await SharedPreferences.getInstance(); premium = !premium; await p.setBool('admin_premium', premium); setState((){});} )]),
      body: resumes.isEmpty ? Center(child: ElevatedButton(onPressed:_new, child: Text('Create your first resume'))) : ListView.builder(itemCount: resumes.length, itemBuilder: (c,i){
        final r = resumes[i];
        return Card(child: ListTile(title: Text(r['title'] ?? 'Untitled'), subtitle: Text(r['name'] ?? ''), onTap: ()=>_edit(i)));
      }),
      floatingActionButton: FloatingActionButton(onPressed: _new, child: Icon(Icons.add)),
    );
  }
}

class EditorScreen extends StatefulWidget {
  final Map<String,dynamic> data;
  final bool premium;
  EditorScreen({required this.data, required this.premium});
  @override _EditorScreenState createState()=>_EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late Map<String,dynamic> r;
  final _form = GlobalKey<FormState>();
  @override void initState(){ super.initState(); r = Map<String,dynamic>.from(widget.data); }

  void _save(){ Navigator.pop(context, r); }

  void _preview() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (ctx) => pw.Center(child: pw.Text(r['name'] ?? ''))));
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: '${(r['title'] ?? 'resume').toString().replaceAll(' ', '_')}.pdf');
  }

  String _mockAI(String s){
    if(s.trim().isEmpty) return s;
    return '- ' + s.replaceAll('.', '').trim();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(actions: [IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: _preview), IconButton(icon: Icon(Icons.save), onPressed: _save)]),
      body: Padding(p: EdgeInsets.all(12), child: Form(key: _form, child: ListView(children: [
        TextFormField(initialValue: r['title'], decoration: InputDecoration(labelText:'Resume title'), onChanged: (v)=>r['title']=v),
        SizedBox(height:8),
        TextFormField(initialValue: r['name'], decoration: InputDecoration(labelText:'Full name'), onChanged: (v)=>r['name']=v),
        SizedBox(height:8),
        TextFormField(initialValue: r['email'], decoration: InputDecoration(labelText:'Email'), onChanged: (v)=>r['email']=v),
        SizedBox(height:8),
        TextFormField(initialValue: r['phone'], decoration: InputDecoration(labelText:'Phone'), onChanged: (v)=>r['phone']=v),
        SizedBox(height:8),
        TextFormField(initialValue: r['summary'], decoration: InputDecoration(labelText:'Professional summary'), maxLines:4, onChanged:(v)=>r['summary']=v),
        SizedBox(height:6),
        Row(children:[ElevatedButton(onPressed: (){ r['summary']=_mockAI(r['summary'] ?? ''); setState((){}); }, child: Text('AI rewrite (mock)')), SizedBox(width:8), Text('(offline)')]),
        SizedBox(height:12),
        TextFormField(initialValue: r['skills'], decoration: InputDecoration(labelText:'Skills (comma separated)'), onChanged:(v)=>r['skills']=v),
        SizedBox(height:20),
      ]))),
    );
  }
}
