//
//  ChatLogController.swift
//  ChatApp-Swift-And-Firebase
//
//  Created by Surya on 9/29/17.
//  Copyright © 2017 Surya. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class ChatLogController: UICollectionViewController,UITextFieldDelegate,UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    let cellId = "CellID"
    var messages = [Message]()
    
    var user : Person? {
        didSet {
            navigationItem.title = user?.name
            observeMessage()
        }
    }
    
    lazy var containerview: UIView = {
        let cView = UIView()
        cView.backgroundColor = UIColor.white
        return cView
    }()
    
    lazy var inputTextField: UITextField = {
        let inputTf = UITextField()
        inputTf.placeholder = "Enter Message ....."
        inputTf.translatesAutoresizingMaskIntoConstraints = false
        inputTf.delegate = self
        inputTf.backgroundColor = UIColor.clear
        return inputTf
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = UIColor.white
        collectionView?.contentInset = UIEdgeInsetsMake(8, 0, 8, 0)
//        collectionView?.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 50, 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.keyboardDismissMode = .interactive
        self.setUpInputComponents()
        setUpKeyboardObservers()
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return containerview
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var containerViewBottomAncher: NSLayoutConstraint?
    
    func setUpInputComponents() {
        
        containerview.frame = CGRect.init(x: 0, y: 0, width: view.frame.size.width, height: 50)

        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage.init(named: "upload-image")
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(handelUploadImage)))
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        containerview.addSubview(uploadImageView)
        
        uploadImageView.leftAnchor.constraint(equalTo: containerview.leftAnchor, constant: 10).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor.lightGray
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        containerview.addSubview(separatorView)
        
        
        separatorView.leftAnchor.constraint(equalTo: containerview.leftAnchor).isActive = true
        separatorView.rightAnchor.constraint(equalTo: containerview.rightAnchor).isActive = true
        separatorView.topAnchor.constraint(equalTo: containerview.topAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(checkTFisEmpty), for: .touchUpInside)
        containerview.addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: containerview.rightAnchor, constant: -20).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: sendButton.intrinsicContentSize.width).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerview.heightAnchor).isActive = true
        
        containerview.addSubview(inputTextField)

        inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor , constant: 10).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
//        inputTf.widthAnchor.constraint(equalToConstant: containerview.frame.size.width - sendButton.frame.size.width).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -10).isActive = true
        inputTextField.heightAnchor.constraint(lessThanOrEqualTo: containerview.heightAnchor).isActive = true
    }
    
    func checkTFisEmpty() {
        if inputTextField.text == ""{
            return
        }else {
           handelSend()
        }
    }
    
    
    func handelSend() {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        let timeStamp = NSNumber.init(value: Date().timeIntervalSince1970)
        let values = ["text":inputTextField.text!, "toId":toId, "fromId":fromId, "timeStamp":timeStamp] as [String : Any]
        childRef.updateChildValues(values)
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            
            self.inputTextField.text = nil
            
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = childRef.key
            userMessageRef.updateChildValues([messageId: 1])
            
            let recipentUserMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipentUserMessageRef.updateChildValues([messageId: 1])
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        checkTFisEmpty()
        textField.resignFirstResponder()
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        let messages = self.messages[indexPath.item]
        cell.textView.text = messages.text
        
        setUpCell(cell: cell, messages: messages)
        
        if let text = messages.text {
            cell.bubbleWidthAnchor?.constant = estimatedHeightBasedOnText(text: text).width + 32
        }
        
        return cell
    }
    
    private func setUpCell(cell: ChatMessageCell, messages: Message){
        
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImagesUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if messages.fromId == Auth.auth().currentUser?.uid {
            cell.bubbleView.backgroundColor = UIColor.init(r: 0, g: 137, b: 249)
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
        }else {
            cell.bubbleView.backgroundColor = UIColor.init(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        if let messageImageUrl = messages.imageUrl {
            cell.messageImageView.loadImagesUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        }else {
            cell.messageImageView.isHidden = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        if let text = messages[indexPath.row].text {
            height = estimatedHeightBasedOnText(text: text).height + 20
        }
        
        return CGSize.init(width: view.frame.width, height: height)
    }
    
    private func estimatedHeightBasedOnText(text: String) -> CGRect{
       let size = CGSize.init(width: 200, height: 1000)
       let option = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
       return NSString.init(string: text).boundingRect(with: size, options: option, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func observeMessage() {
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
            return
        }
        let userMessageRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        userMessageRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dict = snapshot.value as? [String: AnyObject] else {
                    return
                }
                let message = Message()
                message.setValuesForKeys(dict)
                    self.messages.append(message)
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                    }
            }, withCancel: nil)
        }, withCancel: nil)
    }

    func setUpKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handelKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handelKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    func handelKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue
        let keyboardDuration = (notification.userInfo![UIKeyboardAnimationDurationUserInfoKey]! as AnyObject).doubleValue
        containerViewBottomAncher?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    func handelKeyboardWillHide(notification: NSNotification){
//        let keyboardFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue
        containerViewBottomAncher?.constant = 0
        let keyboardDuration = (notification.userInfo![UIKeyboardAnimationDurationUserInfoKey]! as AnyObject).doubleValue
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    func handelUploadImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        }else if let origionalImage = info["UIImagePickerControllerOrigionalImage"] as? UIImage {
            selectedImageFromPicker = origionalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorage(selectedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadToFirebaseStorage(_ image: UIImage) {
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print("Failed to Upload Image:",error!)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    self.sendMessageWithImageUrl(imageUrl)
                }
            })
        }
    }
    
    private func sendMessageWithImageUrl(_ imageUrl: String){
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        let timeStamp = NSNumber.init(value: Date().timeIntervalSince1970)
        let values = ["imageUrl":imageUrl, "toId":toId, "fromId":fromId, "timeStamp":timeStamp] as [String : Any]
        childRef.updateChildValues(values)
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            self.inputTextField.text = nil
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = childRef.key
            userMessageRef.updateChildValues([messageId: 1])
            
            let recipentUserMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipentUserMessageRef.updateChildValues([messageId: 1])
        }
    }
}

