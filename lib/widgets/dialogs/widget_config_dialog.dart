
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:home_widget_counter/helper/settings_helper.dart';
import 'package:home_widget_counter/models/tag_model.dart';
import 'package:home_widget_counter/widgets/dialogs/show_tag_search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home_widget.dart';

Future<void> showForm(BuildContext context, String title) async {
  List<TagModel> selectedTags = [];

  final formKey = GlobalKey<FormBuilderState>();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FormBuilder(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Font Size',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  FormBuilderSlider(
                    name: 'fontSize',
                    initialValue: 20,
                    min: 10,
                    max: 30,
                    divisions: 20,
                    decoration: const InputDecoration(
                      labelText: 'Adjust the font size',
                      labelStyle: TextStyle(fontSize: 16),
                      helperText: 'Slide to select a font size (10 to 30)',
                      helperStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10), // Reduced spacing here
                  const Text(
                    'Widget Size',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  FormBuilderDropdown(
                    name: 'size',
                    decoration: const InputDecoration(
                      labelText: 'Select the widget size',
                      labelStyle: TextStyle(fontSize: 16),
                    ),
                    items: ['small', 'large']
                        .map((val) => DropdownMenuItem(
                      value: val.toString(),
                      child: Text(val.toString()),
                    ),)
                        .toList(),
                  ),
                  const SizedBox(height: 10), // Reduced spacing here
                  const Text(
                    'Display Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  FormBuilderDropdown(
                    name: 'order',
                    decoration: const InputDecoration(
                      labelText: 'select the order to display',
                      labelStyle: TextStyle(fontSize: 16),
                    ),
                    items: ['Random', 'Ascending','Descending']
                        .map((val) => DropdownMenuItem(
                      value: val.toString(),
                      child: Text(val.toString()),
                    ),)
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  RichText(text: const TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(text: 'Note: ',style:TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: 'Using small size for font size above 20 may clip the content.'),
                      ],
                  ),),
                  const SizedBox(height: 20),
                  ShowTagSearch(selectedTags: selectedTags,),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.isValid) {
                          formKey.currentState!.saveAndValidate();
                          SettingsHelper.saveTags(selectedTags);
                          await prefs.setString(
                              'fontSize',
                              formKey.currentState!.fields['fontSize']!.value.toString(),);
                          await prefs.setString('order', formKey.currentState!.fields['order']!.value.toString());
                          Navigator.pop(context);
                          await _requestToPinWidget(formKey.currentState!.fields['size']!.value);
                        }
                      },
                      child: const Text('Add'),
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
    size == 'small'
        ? await HomeWidget.requestPinWidget(
      androidName: 'QuoteGlanceWidgetReceiverSmall',
    )
        : await HomeWidget.requestPinWidget(
      androidName: 'QuoteGlanceWidgetReceiverLarge',
    );
  }
}
