// Copyright 2018-present the Material Components for iOS authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

/*
 in progress:
  * scroll labels/chips view to the left, when not enough room for typing
 todo:
  * change labels to buttons (verifying interactivity of individual chips)
  * "enter" to create a chip - usability issue
  * scrolling through label/chips.
  * scroll the overlay view to correct position on focus and un-focus events (textFieldDidBeginEditing: ?)
  * RTL Support
  * backspace to select and then delete an entire label/chip
  * tap to select a chip + another tap to remove it - if in the middle of the list. required?
 done:
  * convert text to label when pressing enter
 */

class UITextFieldWithChipsExample: UIViewController {

  let textField = InsetTextField()
  var leftView = UIView()
//  var trailingConstraint: NSLayoutConstraint?
  var leadingConstraint: NSLayoutConstraint?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.view.backgroundColor = UIColor.white

    setupExample()
    additionalTextField()

    // this fixes the issue of the cursor becoming half size when the field is empty
    DispatchQueue.main.async {
      self.textField.becomeFirstResponder()
    }
  }

  func setupExample() {

    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.backgroundColor = UIColor.orange.withAlphaComponent(0.05)
    textField.layer.borderWidth = 1.0
    textField.layer.borderColor = UIColor.orange.cgColor
    textField.textColor = .orange
    textField.text = "Hit Enter Here"

    // when on, enter responds to auto-correction which is confusing when we're trying to create "chips"
    textField.autocorrectionType = UITextAutocorrectionType.no

    textField.delegate = self

    textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

    view.addSubview(textField)

    // position the textfield somewhere in the screen
    if #available(iOSApplicationExtension 11.0, *) {
      let guide = view.safeAreaLayoutGuide
      textField.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20.0).isActive = true
      textField.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20.0).isActive = true
      textField.topAnchor.constraint(equalTo: guide.topAnchor, constant: 40.0).isActive = true
    } else if #available(iOSApplicationExtension 9.0, *) {
      textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.0).isActive = true
      textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0).isActive = true
      textField.topAnchor.constraint(equalTo: view.topAnchor, constant: 40.0).isActive = true
    } else {
      // Fallback on earlier versions
      print("This example is supported on iOS version 9 or later.")
    }

    leftView.translatesAutoresizingMaskIntoConstraints = false
    leftView.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)

    leftView.clipsToBounds = true
    textField.leftView = leftView
    textField.leftViewMode = .always
  }

  func additionalTextField() {
    let additionalTextField = PlainTextField()
    additionalTextField.translatesAutoresizingMaskIntoConstraints = false
    additionalTextField.backgroundColor = UIColor.orange.withAlphaComponent(0.05)
    additionalTextField.layer.borderWidth = 1.0
    additionalTextField.layer.borderColor = UIColor.orange.cgColor
    additionalTextField.textColor = .orange
    additionalTextField.text = "Just a Textfield"

    // when on, enter responds to auto-correction which is confusing when we're trying to create "chips"
    additionalTextField.autocorrectionType = UITextAutocorrectionType.no

    view.addSubview(additionalTextField)

    // position the textfield somewhere in the screen
    if #available(iOSApplicationExtension 9.0, *) {
      additionalTextField.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
      additionalTextField.trailingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
      additionalTextField.topAnchor.constraint(equalTo: textField.topAnchor, constant: 40.0).isActive = true
    } else {
      // Fallback on earlier versions
      print("This example is supported on iOS version 9 or later.")
    }
  }

  func appendLabel(text: String) {

    let pad: CGFloat = 5.0

    // create label and add to left view
    let label = newLabel(text: text)
    let lastLabel = leftView.subviews.last
    leftView.addSubview(label)

    // add constraints
    var lastmax: CGFloat = 0
    if #available(iOSApplicationExtension 9.0, *) {
      label.topAnchor.constraint(equalTo: leftView.topAnchor).isActive = true
      label.bottomAnchor.constraint(equalTo: leftView.bottomAnchor).isActive = true
      if let lastLabel = lastLabel {
        label.leadingAnchor.constraint(equalTo: lastLabel.trailingAnchor, constant: pad).isActive = true
        //label.leadingAnchor.constraint(equalTo: lastLabel.trailingAnchor, constant: pad).isActive = true
        //lastmax = lastLabel.frame.maxX
      } else {
        leadingConstraint = label.leadingAnchor.constraint(equalTo: leftView.leadingAnchor)
        leadingConstraint?.priority = UILayoutPriorityDefaultLow
        leadingConstraint?.isActive = true
      }
//      if let trailingConstraint = self.trailingConstraint {
//        leftView.removeConstraint(trailingConstraint)
//      }
//      trailingConstraint = label.trailingAnchor.constraint(equalTo: leftView.trailingAnchor)
//      trailingConstraint?.isActive = true
    } else {
      // Fallback on earlier versions
      print("This example is supported on iOS version 9 or later.")
    }

    // adjust text field's inset and width
    leftView.layoutIfNeeded()
    //label.frame.origin.x = lastmax
    textField.insetX = label.frame.maxX
  }

  func newLabel(text: String) -> UILabel {
    // create label and add to left view
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.backgroundColor = UIColor.red.withAlphaComponent(0.4)
    label.text = " " + text + " "
    label.textColor = .white
    label.layer.cornerRadius = 3.0
    label.layer.masksToBounds = true
    return label
  }
}

// MARK: Example Extensions

extension UITextFieldWithChipsExample: UITextFieldDelegate {

  // listen to "enter" key
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if string == "\n" {
      if let trimmedText = textField.text?.trimmingCharacters(in: .whitespaces), trimmedText.count > 0 {
        appendLabel(text: trimmedText)
        textField.text = ""
      }
    }

    //setupEditingRect(string: string)

    //print("  string:\(string) range: \(range)")
    return true
  }

  func setupEditingRect(string: String) {
    //let editingrect = textField.editingRect(forBounds: textField.bounds)

    let START_SCROLL_POS: CGFloat = 30.0

    let textrect = textField.textRect(forBounds: textField.bounds)
    let editingrect = textField.editingRect(forBounds: textField.bounds)
//    print("> insetX:\((textField as! InsetTextField).insetX) textrect:\(textrect) [\(string)]")

    let offset = textField.offset(from: textField.beginningOfDocument, to: textField.endOfDocument)
    let position = textField.position(from: textField.beginningOfDocument, offset: offset)

    let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: textField.endOfDocument)
    if let insetTextField = textField as? InsetTextField,
      let textrange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument) {
      let firstrect = textField.firstRect(for: textrange)
//      print("  cursorPosition:\(cursorPosition) | textrange:\(textrange) | rect:\(firstrect)")

      let textInputView = textField.textInputView
      let textInputViewRect = textField.textInputView.frame
      let convertedrect = textField.convert(firstrect, from: textInputView)

      // if space is too small for typing, we need to make more room - by moving the split point
      let textWidth = firstrect.width
      let fieldWidth = textrect.width
      let space = fieldWidth - textWidth
      //if space < START_SCROLL_POS {
//        print("(need more space!) cursorPosition:\(cursorPosition) space: \(space) textWidth:\(textWidth)")
      if space < 0 {
        insetTextField.insetX += space
        if let leadingConstraint = leadingConstraint {
          //leftView.removeConstraint(leadingConstraint)
          leadingConstraint.constant += space
        }
        insetTextField.layoutIfNeeded()
        let textrange1 = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        let rect2 = textField.firstRect(for: textrange)
//        print("  new insetX:\(insetTextField.insetX) | rect-after:\(rect2)")
      }

      print("[\(string)]: space:\(space) \(space < 0 ? "OFFSET" : "") firstrect:\(firstrect.width) insetX:\(insetTextField.insetX) textrect:\(textrect.width) textInput:\(textInputViewRect.width)")

//      insetTextField.layoutIfNeeded()
//      let textrange1 = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
//      let rect2 = textField.firstRect(for: textrange)
    }
  }

  @objc func textFieldDidChange(_ textField: UITextField) {
    setupEditingRect(string: textField.text ?? "")
  }
}

extension UITextFieldWithChipsExample {
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
}

extension UITextFieldWithChipsExample {

  class func catalogMetadata() -> [String: Any] {
    return [
      "breadcrumbs": ["Action Sheet", "A UI Text Fields With (Simulated) Chips"],
      //"breadcrumbs": ["Text Field", "UI Text Fields With (Simulated) Chips"],
      "primaryDemo": false,
      "presentable": false,
    ]
  }
}

// MARK: UITextField Subclass

class InsetTextField: UITextField {

  // the split point: this is the x position where chips view ends and text begins.
  // Updating this property moves the split point between chips & text.
  var insetX: CGFloat = 8.0

  // default padding for the textfield, taking insetX into account for the left position
  let insetRect = UIEdgeInsets(top: 5.0, left: 8.0, bottom: 5.0, right: 8.0)

  // text bounds
  override func textRect(forBounds bounds: CGRect) -> CGRect {
    let superbounds = super.textRect(forBounds: bounds)
    var newbounds = UIEdgeInsetsInsetRect(superbounds, insetRect)
    newbounds.origin.x = insetX
    // print("textRect: \(superbounds) | \(newbounds)")
    return newbounds
  }

  // text bounds while editing
  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    let superbounds = super.editingRect(forBounds: bounds)
    var newbounds = UIEdgeInsetsInsetRect(superbounds, insetRect)
    newbounds.origin.x = insetX
     //print("editingRect: \(superbounds) | \(newbounds)")
    return newbounds
  }

  // left view bounds
  override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
    let superbounds = super.leftViewRect(forBounds: bounds)
    var newbounds = superbounds
    newbounds.size.width = insetX //- 10
//    print(". leftViewRect: \(newbounds.origin.x)-\(newbounds.width) insetX:\(insetX) | leftView: \(leftView!.frame.origin.x)-\(leftView!.frame.width)")
    return newbounds
  }
}

class PlainTextField: UITextField {

  // default padding for the textfield, taking insetX into account for the left position
  let insetRect = UIEdgeInsets(top: 5.0, left: 8.0, bottom: 5.0, right: 8.0)

  // text bounds
  override func textRect(forBounds bounds: CGRect) -> CGRect {
    let superbounds = super.textRect(forBounds: bounds)
    let newbounds = UIEdgeInsetsInsetRect(superbounds, insetRect)
    return newbounds
  }

  // text bounds while editing
  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    let superbounds = super.editingRect(forBounds: bounds)
    let newbounds = UIEdgeInsetsInsetRect(superbounds, insetRect)
    return newbounds
  }
}
