//
//  AddGameViewController.swift
//  queRule
//
//  Created by Juan Manuel Jimenez Sanchez on 8/02/17.
//  Copyright © 2017 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

protocol AddGameViewControllerDelegate {
    func didAddGame()
}

class AddGameViewController: UIViewController {
    
    @IBOutlet weak var gameImageView: UIImageView!
    @IBOutlet weak var borrowedSwitch: UISwitch!
    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var txtBorrowedTo: UITextField!
    @IBOutlet weak var txtBorrowedDate: UITextField!
    @IBOutlet weak var btnDelete: UIButton!
    
    var managedObjectContext: NSManagedObjectContext? = nil
    
    var imagePickerController = UIImagePickerController()
    var cameraPermissions: Bool = false
    
    var delegate: AddGameViewControllerDelegate?
    
    var game: Game? = nil
    
    var datePicker: UIDatePicker!
    
    let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dateFormatter.dateFormat = "dd/MM/yyyy"
        
        //El NotificationCenter nos avisará cuando el teclado se oculte o aparezca
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        //Para reconocer el gesto de cuando tocan la pantalla y poder ocultar el teclado
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)
        
        //Para reconocer el gesto de cuando tocan la imagen para poder mostrar el selector de imagen
        let takePictureGesture = UITapGestureRecognizer(target: self, action: #selector(takePictureTapped))
        self.gameImageView.addGestureRecognizer(takePictureGesture)
        
        self.imagePickerController.delegate = self
        self.imagePickerController.allowsEditing = true
        
        self.datePicker = UIDatePicker(frame: CGRect(x: 0, y: 210, width: 320, height: 216))
        self.datePicker.datePickerMode = .date
        self.datePicker.addTarget(self, action: #selector(datePickerChangedValue), for: .valueChanged)
        self.txtBorrowedDate.inputView = self.datePicker
        
        if self.game == nil {
            self.title = "Añadir Juego"
            
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonPressed))
            
            self.btnDelete.isHidden = true
            self.borrowedSwitch.isOn = false
        } else {
            self.title = "Detalles"
            self.txtTitle.text = self.game?.title
            
            if let borrowed = self.game?.borrowed {
                self.borrowedSwitch.isOn = borrowed
            }
            
            self.txtBorrowedTo.text = self.game?.borrowedTo
            
            if let borrowedDate = self.game?.borrowedDate as? Date {
                self.txtBorrowedDate.text = dateFormatter.string(from: borrowedDate)
            }
            
            if let imageData = self.game?.image as? Data {
                self.gameImageView.image = UIImage(data: imageData)
            }
            
            self.btnDelete.isHidden = false
        }
        
        if !self.borrowedSwitch.isOn {
            self.txtBorrowedTo.isEnabled = false
            self.txtBorrowedDate.isEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.checkPermissions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.game != nil {
            self.saveGame()
        }
    }
    
    ///Desplazamos la vista hacia arriba la misma cantidad de espacio que va a ocupar el teclado para que no quede oculta
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        UIView.animate(withDuration: keyboardTime) { 
            self.view.frame.origin.y = -(keyboardFrame.height)
        }
    }
    
    ///Cuando el teclado se oculta volvemos a mover la vista a su posición original
    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = 0
        }
    }
    
    ///Ocultamos el teclado
    func viewTapped() {
        for view in self.view.subviews {
            //Si la vista es un TextField...
            if let textField = view as? UITextField {
                textField.resignFirstResponder()
            }
        }
    }
    
    func checkPermissions() {
        let cameraMediaType = AVMediaTypeVideo
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
        
        switch cameraAuthorizationStatus {
        case .authorized:
            self.cameraPermissions = true
        case .restricted:
            self.cameraPermissions = false
        case .denied:
            self.cameraPermissions = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType, completionHandler: { (granted) in
                self.cameraPermissions = granted
            })
        }
    }
    
    ///Muestra el actionSheet con las opciones disponibles (camara y/o galería) y presenta el imagePickerController
    func takePictureTapped() {
        guard self.cameraPermissions else {
            let permissionsAlertController = UIAlertController(title: "Permisos", message: "No tiene permisos para acceder a la camara del dispositivo. Puede cambiar esta informacíon en la App de ajustes de iOS", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            permissionsAlertController.addAction(okAction)
            
            present(permissionsAlertController, animated: true, completion: nil)
            
            return
        }
        
        let alertController = UIAlertController(title: "Añadir fotos del videojuego", message: "", preferredStyle: .actionSheet)
        let cameraOption = UIAlertAction(title: "Cámara", style: .default, handler: { (alertAction) in
            self.imagePickerController.sourceType = .camera
            self.present(self.imagePickerController, animated: true, completion: nil)
        })
        let cameraRollOption = UIAlertAction(title: "Carrete", style: .default, handler: { (alertAction) in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true, completion: nil)
        })
        let cancelOption = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            alertController.addAction(cameraOption)
        }
        
        alertController.addAction(cameraRollOption)
        alertController.addAction(cancelOption)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func datePickerChangedValue(picker: UIDatePicker) {
        self.txtBorrowedDate.text = self.dateFormatter.string(from: picker.date)
    }
    
    func saveButtonPressed() {
        self.saveGame()
        dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    func saveGame() {
        if let context = self.managedObjectContext {
            var editedGame: Game? = nil
            if self.game == nil {
                editedGame = Game(context: context)
            } else {
                editedGame = game
            }
            
            if let editedGame = editedGame {
                editedGame.dateCreated = NSDate()
                if let title = self.txtTitle.text {
                    editedGame.title = title
                }
                editedGame.borrowed = borrowedSwitch.isOn
                if let image = self.gameImageView.image {
                    editedGame.image = UIImagePNGRepresentation(image) as NSData?
                } else {
                    editedGame.image = NSData()
                }
                
                if editedGame.borrowed {
                    if let borrowedTo = self.txtBorrowedTo.text {
                        editedGame.borrowedTo = borrowedTo.uppercased()
                    }
                    if let strDate = self.txtBorrowedDate.text {
                        editedGame.borrowedDate = dateFormatter.date(from: strDate) as NSDate?
                    }
                } else {
                    editedGame.borrowedTo = nil
                    editedGame.borrowedDate = nil
                }
                
                do {
                    try context.save()
                    self.delegate?.didAddGame()
                } catch {
                    print("Ha habido un error al guardar en Core Data")
                }
            }
        }
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            self.txtBorrowedTo.isEnabled = true
            self.txtBorrowedDate.isEnabled = true
            self.txtBorrowedDate.text = dateFormatter.string(from: Date())
        } else {
            self.txtBorrowedTo.isEnabled = false
            self.txtBorrowedDate.isEnabled = false
            self.txtBorrowedTo.text = ""
            self.txtBorrowedDate.text = ""
        }
    }
    
    @IBAction func deletePressed(_ sender: UIButton) {
        if let context = self.managedObjectContext {
            context.delete(game!)
            game = nil
            self.delegate?.didAddGame()
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
}

extension AddGameViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.gameImageView.image = pickedImage
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}
