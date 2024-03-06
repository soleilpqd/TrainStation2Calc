/*
  Train Station 2 Calculator - Simple resource calculator to play TrainStation2
  Copyright © 2024 SoleilPQD

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

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