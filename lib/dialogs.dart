import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> inputNumberDialogBuilder(BuildContext context, String title, String initValue, Function(String) completion) {
  TextEditingController controller = TextEditingController(text: initValue);
  return showDialog<void>(
    context: context,
    builder: (dlgCtx) {
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
              Navigator.of(dlgCtx).pop();
            },
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(dlgCtx).pop();
              completion(controller.text);
            },
          ),
        ],
      );
    },
  );
}

void showRetry(BuildContext context, String title, String message, Function() retry) {
  showDialog(context: context, builder: ((dlgCtx) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dlgCtx).pop();
            retry();
          },
          child: const Text("Retry")
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dlgCtx).pop();
          },
          child: const Text("Close")
        )
      ],
    );
  }));
}