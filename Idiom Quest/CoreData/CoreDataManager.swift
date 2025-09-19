//
//  CoreDataManager.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 11/9/2025.
//

import CoreData

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    
    private init() {
        guard let modelURL = Bundle.main.url(forResource: "Idiom_Quest", withExtension: "momd") else {
            print("Bundle contents for momd: \(Bundle.main.paths(forResourcesOfType: "momd", inDirectory: nil))")
            fatalError("Cannot find Idiom_Quest.momd in bundle")
        }
        print("Model URL: \(modelURL.path)")
        
        persistentContainer = NSPersistentContainer(name: "Idiom_Quest")
        
        // Read-only store: ChengyuData.sqlite
        guard let chengyuStoreURL = Bundle.main.url(forResource: "ChengyuData", withExtension: "sqlite") else {
            print("Bundle contents for sqlite: \(Bundle.main.paths(forResourcesOfType: "sqlite", inDirectory: nil))")
            fatalError("Cannot find ChengyuData.sqlite in bundle")
        }
        let chengyuDescription = NSPersistentStoreDescription(url: chengyuStoreURL)
        chengyuDescription.type = NSSQLiteStoreType
        chengyuDescription.isReadOnly = true
        // Removed configuration reference that doesn't exist in model
        
        // Writable store: UserData.sqlite
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let userDataStoreURL = documentsURL.appendingPathComponent("UserData.sqlite")
        let userDataDescription = NSPersistentStoreDescription(url: userDataStoreURL)
        userDataDescription.type = NSSQLiteStoreType
        // Removed configuration reference that doesn't exist in model
        userDataDescription.shouldMigrateStoreAutomatically = true
        userDataDescription.shouldInferMappingModelAutomatically = true
        
        // Ensure directory exists
        let storeDirectory = userDataStoreURL.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true, attributes: nil)
            print("Created directory for UserData.sqlite: \(storeDirectory.path)")
        } catch {
            print("Failed to create directory for UserData.sqlite: \(error)")
        }
        
        print("Chengyu Store URL: \(chengyuStoreURL.path)")
        print("Chengyu File exists: \(fileManager.fileExists(atPath: chengyuStoreURL.path))")
        print("UserData Store URL: \(userDataStoreURL.path)")
        print("UserData File exists: \(fileManager.fileExists(atPath: userDataStoreURL.path))")
        
        persistentContainer.persistentStoreDescriptions = [chengyuDescription, userDataDescription]
        
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Error loading store at \(storeDescription.url?.path ?? "unknown"): \(error), \(error.userInfo)")
                
                // If this is the UserData store and it has corruption, try to recreate it
                if let url = storeDescription.url, url.lastPathComponent == "UserData.sqlite" {
                    print("Attempting to recreate corrupted UserData store...")
                    do {
                        try FileManager.default.removeItem(at: url)
                        // Try to reload just this store
                        self.persistentContainer.loadPersistentStores { _, retryError in
                            if let retryError = retryError {
                                fatalError("Failed to recreate UserData store: \(retryError)")
                            }
                            print("Successfully recreated UserData store")
                        }
                    } catch {
                        print("Failed to remove corrupted UserData store: \(error)")
//                        fatalError("Failed to load Core Data store: \(error), \(error.userInfo)")
                    }
                } else {
                    fatalError("Failed to load Core Data store: \(error), \(error.userInfo)")
                }
            } else {
                print("Successfully loaded store: \(storeDescription.url?.path ?? "unknown")")
            }
        }
        
        // Initialize UserData in background
        initializeUserData()
    }
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Context saved successfully")
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func initializeUserData() {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        context.perform {
            do {
                let chengyuRequest = NSFetchRequest<Chengyu>(entityName: "Chengyu")
                let chengyus = try context.fetch(chengyuRequest)
                print("Fetched \(chengyus.count) Chengyu entities")
                
                // Store total count for daily idiom
                UserDefaults.standard.set(chengyus.count, forKey: "totalChengyuCount")
                
                for chengyu in chengyus {
                    let word = chengyu.word
                    let userDataRequest = NSFetchRequest<UserData>(entityName: "UserData")
                    userDataRequest.predicate = NSPredicate(format: "word == %@", word!)
                    
                    let existingUserData = try context.fetch(userDataRequest)
                    if existingUserData.isEmpty {
                        let userData = UserData(context: context)
                        userData.word = word
                        userData.isLearned = false
                        // userData.score = 0 // If score is used
                    }
                }
                
                if context.hasChanges {
                    try context.save()
                    print("Initialized UserData in background context")
                }
            } catch {
                print("Failed to initialize UserData: \(error)")
            }
        }
    }
}
