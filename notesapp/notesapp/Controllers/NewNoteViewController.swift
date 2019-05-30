//
//  NewNoteViewController.swift
//  notesapp
//
//  Created by Vladyslav Kolomiets on 5/24/19.
//  Copyright © 2019 Vladyslav Kolomiets. All rights reserved.
//

import UIKit
import CoreData

class NewNoteViewController: UIViewController {
  
  var currentNote: Note?
  var newNote: Note?
  
  @IBOutlet weak var noteDescriptionTextView: UITextView!
  @IBOutlet weak var saveButton: UIBarButtonItem!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let bgImage = UIImage(named: "texture")
    
    saveButton.isEnabled = false
    setupEditScreen()
    navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
    navigationController?.navigationBar.setBackgroundImage(bgImage, for: .default)
    self.view.backgroundColor = UIColor(patternImage: bgImage!)
    noteDescriptionTextView.backgroundColor = UIColor(patternImage: bgImage!)
    noteDescriptionTextView.delegate = self
    
    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    noteDescriptionTextView.becomeFirstResponder()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    view.endEditing(true)
  }
  
  private func setupEditScreen() {
    if currentNote != nil {
      noteDescriptionTextView.text = currentNote?.noteDescription
      currentNote!.date = Date()
      setupNavigationBar()
    }
  }
  
  private func setupNavigationBar() {
    navigationItem.leftBarButtonItem = nil
    saveButton.isEnabled = true
  }
  
  @IBAction func cancelButtonPressed(_ sender: Any) {
    dismiss(animated: true)
  }
  
  @IBAction func shareButtonPressed(_ sender: Any) {
    let text = noteDescriptionTextView.text
    let textToShare = [text]
    let activityViewController = UIActivityViewController(activityItems: textToShare as [Any], applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = self.view
    self.present(activityViewController, animated: true, completion: nil)
  }
}

// MARK: - Textfield delegate

extension NewNoteViewController: UITextViewDelegate {
  
  func textViewDidChange(_ textView: UITextView) {
    if noteDescriptionTextView.text.isEmpty == false {
      saveButton.isEnabled = true
    } else {
      saveButton.isEnabled = false
    }
  }
  
  func saveNote() {
    if let context = (UIApplication.shared.delegate as? AppDelegate)?.coreDataStack.persistentContainer.viewContext {
      
      if currentNote != nil {
        do {
          try context.save()
          currentNote?.noteDescription = noteDescriptionTextView.text
          currentNote?.date = Date()
        } catch let error as NSError {
          print(error.localizedDescription)
        }
      } else if noteDescriptionTextView.text != "" {
        newNote = Note(context: context)
        newNote!.noteDescription = noteDescriptionTextView.text
        newNote!.date = Date()
        do {
          try context.save()
          print("Success")
        } catch let error as NSError {
          print("Can't save data \(error), \(error.userInfo)")
        }
      } else {
        return
      }
    }
  }
  
  @objc func adjustForKeyboard(notification: Notification) {
    guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
    
    let keyboardScreenEndFrame = keyboardValue.cgRectValue
    let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
    
    if notification.name == UIResponder.keyboardWillHideNotification {
      noteDescriptionTextView.contentInset = .zero
    } else {
      noteDescriptionTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
    }
    
    noteDescriptionTextView.scrollIndicatorInsets = noteDescriptionTextView.contentInset
    
    let selectedRange = noteDescriptionTextView.selectedRange
    noteDescriptionTextView.scrollRangeToVisible(selectedRange)
  }
}

