import 'dart:developer';

import "package:flutter/material.dart";
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home_widget.dart';

Future<void> showForm(BuildContext context, String title) async {
  final _formKey = GlobalKey<FormBuilderState>();
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Font Size',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  FormBuilderSlider(
                    name: 'fontSize',
                    initialValue: 20,
                    min: 10,
                    max: 30,
                    divisions: 20,
                    decoration: InputDecoration(
                      labelText: 'Adjust the font size',
                      labelStyle: TextStyle(fontSize: 16),
                      helperText: 'Slide to select a font size (10 to 30)',
                      helperStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                  SizedBox(height: 10), // Reduced spacing here
                  Text(
                    'Widget Size',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  FormBuilderDropdown(
                    name: 'size',
                    decoration: InputDecoration(
                      labelText: 'Select the widget size',
                      labelStyle: TextStyle(fontSize: 16),
                    ),
                    items: ['small', 'large']
                        .map((val) => DropdownMenuItem(
                      child: Text(val.toString()),
                      value: val.toString(),
                    ))
                        .toList(),
                  ),
                  SizedBox(height: 10), // Reduced spacing here
                  Text(
                    'Display Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  FormBuilderDropdown(
                    name: 'order',
                    decoration: InputDecoration(
                      labelText: 'select the order to display',
                      labelStyle: TextStyle(fontSize: 16),
                    ),
                    items: ['Random', 'Ascending','Descending']
                        .map((val) => DropdownMenuItem(
                      child: Text(val.toString()),
                      value: val.toString(),
                    ))
                        .toList(),
                  ),
                  SizedBox(height: 10),
                  RichText(text: TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(text: "Note: ",style:TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: "Using small size for font size above 20 may clip the content.")
                    ]
                  ),),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.isValid) {
                          _formKey.currentState!.saveAndValidate();
                          await _prefs.setString(
                              "fontSize",
                              _formKey.currentState!.fields["fontSize"]!.value.toString());
                          await _prefs.setString("order", _formKey.currentState!.fields["order"]!.value.toString());
                          Navigator.pop(context);
                          await _requestToPinWidget(_formKey.currentState!.fields["size"]!.value);
                        }
                      },
                      child: Text("Add"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _requestToPinWidget(String size) async {
  final isRequestPinSupported = await HomeWidget.isRequestPinWidgetSupported();
  if (isRequestPinSupported == true) {
    size == "small"
        ? await HomeWidget.requestPinWidget(
      androidName: 'QuoteGlanceWidgetReceiverSmall',
    )
        : await HomeWidget.requestPinWidget(
      androidName: 'QuoteGlanceWidgetReceiverLarge',
    );
  }
}
