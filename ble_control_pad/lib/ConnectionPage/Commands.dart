import 'package:flutter/material.dart';

class CommondsTile extends StatefulWidget {
  final String title;
  final String titlecommand;
  final Function(String) onSubmit;
  CommondsTile({
    @required this.title,
    @required this.titlecommand,
    @required this.onSubmit,
  });

  @override
  _CommondsTileState createState() => _CommondsTileState();
}

class _CommondsTileState extends State<CommondsTile> {
  bool textfiledvis = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(widget.title),
        leading: CircleAvatar(
          child: Text(
            widget.titlecommand,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        trailing: Wrap(
          spacing: 12, // space between two icons
          children: <Widget>[
            Visibility(
              child: SizedBox(
                height: 45,
                width: 45,
                child: TextField(
                  maxLength: 1,
                  decoration: InputDecoration(counterText: ''),
                  onSubmitted: (val) => widget.onSubmit(val),
                ),
              ),
              visible: textfiledvis,
            ),
            IconButton(
              tooltip: "Change Command",
              onPressed: () {
                setState(() {
                  textfiledvis == false
                      ? textfiledvis = true
                      : textfiledvis = false;
                });
              },
              icon: Icon(
                Icons.change_circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
