import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> inputNumberDialogBuilder(BuildContext context, String title, String initValue, Function(String) completion) {
  TextEditingController controller = TextEditingController(text: initValue);
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
            autofocus: true,
            controller: controller,
            decoration: const InputDecoration(labelText: "Input a number"),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ], // Only numbers can be entered
          ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              completion(controller.text);
            },
          ),
        ],
      );
    },
  );
}