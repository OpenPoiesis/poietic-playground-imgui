//
//  App+resources.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 01/02/2026.
//

extension Application {
    func loadResources() {
        let loader = ResourceLoader(Self.DefaultResourcesPath, application: self)
        textures["select"] = loader.loadTexture("icons/black/select.png")
        textures["place"] = loader.loadTexture("icons/black/place.png")
        textures["connect"] = loader.loadTexture("icons/black/connect.png")
        textures["pan"] = loader.loadTexture("icons/black/hand.png")
        print("Loaded textures:")
        for key in textures.keys.sorted() {
            let texture = textures[key]!
            print("    ", key, ":", texture.width, "x", texture.height," ", texture.textureID)
        }
    }
}
