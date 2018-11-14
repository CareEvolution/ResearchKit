//
//  DummyMedPicker.swift
//  ORKCatalog
//
//  Created by Eric Schramm on 5/31/18.
//  Copyright © 2018 researchkit.org. All rights reserved.
//

import ResearchKit

class DummyMedPicker: ORKMedicationPicker {
    
    let medications = [ORKMedication(identifier: ORKMedicationRxNormIdentifier(rxCUI: "123456"), medicationDescription: "acetaminophen (TYLENOL) tablet - 325 mg", detailedDescription: "every 4-6 hours"),
                       ORKMedication(identifier: ORKMedicationRxNormIdentifier(rxCUI: "234567"), medicationDescription: "ibuprofen (MOTRIN) tablet - 200 mg", detailedDescription: "every 4-6 hours alternating"),
                       ORKMedication(identifier: ORKMedicationRxNormIdentifier(rxCUI: "345678"), medicationDescription: "naproxen (ALEVE) tablet - 500 mg", detailedDescription: "every 12 hours scheduled")]
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if (cell == nil) {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        let medication = medications[indexPath.row]
        cell?.textLabel!.text = medication.medicationDescription
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let medication = medications[indexPath.row]
        delegate.medicationPicker(self, selectedMedication: medication)
    }
}
