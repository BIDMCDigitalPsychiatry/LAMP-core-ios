//
//  ComplicationController.swift
//  mindLAMP Consortium
//
//  Created by Zco Engineer on 09/10/20.
//

//TODO: https://developer.apple.com/documentation/clockkit/creating_complications_for_your_watchos_app https://developer.apple.com/documentation/clockkit/declaring_the_complications

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
            let descriptors = [
                CLKComplicationDescriptor(identifier: "complication", displayName: "Latinorum", supportedFamilies: [.circularSmall, .extraLarge, .graphicBezel, .graphicCircular, .graphicCorner, .modularLarge, .modularSmall, .utilitarianLarge, .utilitarianSmall, .utilitarianSmallFlat])
                // Multiple complication support can be added here with more descriptors
            ]
            
            // Call the handler with the currently supported complication descriptors
            handler(descriptors)
        }
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward, .backward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date())
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(nil)
    }
    
}
