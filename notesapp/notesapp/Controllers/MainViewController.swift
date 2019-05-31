//
//  ViewController.swift
//  notesapp
//
//  Created by Vladyslav Kolomiets on 5/24/19.
//  Copyright © 2019 Vladyslav Kolomiets. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: UITableViewController, NSFetchedResultsControllerDelegate {
  
  private var fetchResultsController: NSFetchedResultsController<Note>!
  private var searchController: UISearchController!
  private var filteredResultArray = [Note]()
  private var notes = [Note]()
  private var isFiltering: Bool {
    return searchController.isActive && searchController.searchBar.text != ""
  }
  private let limitCountOfCharacters = 100
  private let fetchSize = 20
  private let startIndex = 0
  private let bgImage = UIImage(named: "texture")
  
  func filterContentFor(searchText text: String) {
    filteredResultArray = notes.filter { (note) -> Bool in
      return (note.noteDescription?.lowercased().contains(text.lowercased()))!
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureSearchController()
    configureTableView()
    searchController.searchBar.delegate = self
    
    let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
    fetchRequest.fetchOffset = startIndex
    fetchRequest.fetchLimit = fetchSize
    let sortDescriptor = NSSortDescriptor(key: "noteDescription", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    if let context = (UIApplication.shared.delegate as? AppDelegate)?.coreDataStack.persistentContainer.viewContext {
      fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
      fetchResultsController.delegate = self
      
      do {
        try fetchResultsController.performFetch()
        notes = fetchResultsController.fetchedObjects!
      } catch let error as NSError {
        print(error.localizedDescription)
      }
    }
  }
  // MARK: - Ferch results controller delegate
  
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    
    switch type {
    case .insert: guard let indexPath = newIndexPath else { break }
    tableView.insertRows(at: [indexPath], with: .automatic)
    case .delete: guard let indexPath = newIndexPath else { break }
    tableView.deleteRows(at: [indexPath], with: .automatic)
    case .update: guard let indexPath = indexPath else { break }
    tableView.reloadRows(at: [indexPath], with: .automatic)
    default:
      tableView.reloadData()
    }
    notes = controller.fetchedObjects as! [Note]
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
  }
  
  func configureSearchController() {
    searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.searchBar.searchBarStyle = .minimal
    searchController.searchBar.backgroundImage = bgImage
    searchController.searchBar.tintColor = #colorLiteral(red: 1, green: 0.662745098, blue: 0.07843137255, alpha: 1)
    searchController.obscuresBackgroundDuringPresentation = false
    navigationItem.searchController = searchController
    definesPresentationContext = true
  }
  
  func configureTableView() {
    let navigationController = self.navigationController
    tableView.tableFooterView = UIView()
    tableView.estimatedRowHeight = 60.0
    tableView.rowHeight = UITableView.automaticDimension
    tableView.backgroundView = UIImageView(image: bgImage)
    navigationController?.navigationBar.prefersLargeTitles = true
    navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
    navigationController?.navigationBar.setBackgroundImage(bgImage, for: .default)
  }
  
  // MARK: - Table view data source
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if isFiltering {
      return filteredResultArray.count
    }
    return notes.count
  }
  
  func noteToDisplayAt(indexPath: IndexPath) -> Note {
    let note: Note
    if isFiltering {
      note = filteredResultArray[indexPath.row]
    } else {
      note = notes[indexPath.row]
    }
    return note
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
    let note = noteToDisplayAt(indexPath: indexPath)
    
    cell.notesLabel?.text = note.value(forKeyPath: "noteDescription") as? String
    cell.notesLabel?.text = cell.notesLabel?.text!.maxLength(length: self.limitCountOfCharacters)
    
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    if let creationDate = note.date {
      cell.dateLabel.text = formatter.string(from: creationDate)
    }
    cell.backgroundView = UIImageView(image: bgImage)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
    let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (_, _) in
      self.notes.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .automatic)
      if let context = (UIApplication.shared.delegate as? AppDelegate)?.coreDataStack.persistentContainer.viewContext {
        
        let objectToDelete = self.fetchResultsController.object(at: indexPath)
        context.delete(objectToDelete)
        
        do {
          try context.save()
        } catch {
          print(error.localizedDescription)
        }
      }
    }
    return [deleteAction]
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showNote" {
      guard let indexPath = tableView.indexPathForSelectedRow else { return }
      let newNoteVC = segue.destination as! NewNoteViewController
      newNoteVC.currentNote = noteToDisplayAt(indexPath: indexPath)
    }
  }
  
  @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
    guard let newNoteVC = segue.source as? NewNoteViewController else { return }
    newNoteVC.saveNote()
    tableView.reloadData()
  }
  
  @IBAction func sortButtonPressed(_ sender: Any) {
    let alert = UIAlertController(title: "Sort by:", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Name", style: .default, handler: { _ in
      print("User click Name button")
    }))
    alert.addAction(UIAlertAction(title: "Date", style: .default, handler: { _ in
      print("User click Date button")
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
      print("User click Cancel button")
    }))
    alert.view.tintColor = #colorLiteral(red: 1, green: 0.662745098, blue: 0.07843137255, alpha: 1)
    self.present(alert, animated: true, completion: nil)
  }
}

extension String {
  func maxLength(length: Int) -> String {
    var str = self
    let nsString = str as NSString
    if nsString.length >= length {
      str = nsString.substring(with:
        NSRange(
          location: 0,
          length: nsString.length > length ? length : nsString.length)
        ) + "..."
    }
    return str
  }
}

extension MainViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    filterContentFor(searchText: searchController.searchBar.text!)
    tableView.reloadData()
  }
}

extension MainViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
      resetSearchState()
  }
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchController.searchBar.showsCancelButton = true
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    resetSearchState()
  }
  
  func resetSearchState() {
    searchController.searchBar.showsCancelButton = false
    searchController.searchBar.endEditing(true)
  }
}

