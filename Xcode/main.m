//
//  main.m
//  cal
//
//  Created by Nicolas Seriot on 12/11/14.
//  Copyright (c) 2014 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

void showHelp() {
    printf("Usage: icalreport [-h] [-l] -c -f FROM_DATE -t TO_DATE\n");
    printf("\n");
    printf("Report the time spent on projects by reading iCal events.\n");
    printf("\n");
    printf("  -h    show this help message and exit\n");
    printf("  -l    use project name in event location (default is title)\n");
    printf("  -c    calendar name\n");
    printf("  -f    from date, yyyy-MM-dd format\n");
    printf("  -t    to date, yyyy-MM-dd format\n");
}

NSDictionary *argumentsDictionary() {
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    
    __block NSMutableDictionary *md = [[NSMutableDictionary alloc] init];
    
    __block NSString *key = nil;
    
    [arguments enumerateObjectsUsingBlock:^(NSString *s, NSUInteger idx, BOOL *stop) {
        if(idx == 0) return;
        
        NSString *value = @"";
        
        if([s hasPrefix:@"-"]) {
            key = s;
        } else {
            value = s;
        }
        
        if(key == nil) return;
        
        md[key] = value;
    }];
    
    return md;
}

NSDate *dateFromString(NSString *s) {
    static NSDateFormatter *df = nil;
    if(df == nil) {
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd"];
    }
    return [df dateFromString:s];
}

NSDictionary *projectsDictionaryFromEvents(NSArray *events, BOOL useLocationInsteadOfTitle) {
    NSMutableDictionary *projectsDictionary = [[NSMutableDictionary alloc] init];
    
    for(EKEvent *e in events) {
        NSString *name = useLocationInsteadOfTitle ? e.location : e.title;
        if(name == nil) name = @"";
        
        NSTimeInterval duration = [e.endDate timeIntervalSinceDate:e.startDate];
        if([[projectsDictionary allKeys] containsObject:name]) {
            duration += [projectsDictionary[name] doubleValue];
        }
        projectsDictionary[name] = @(duration);
    }
    return projectsDictionary;
}

void printReport(NSDictionary *projectsDictionary, NSString *fromDateString, NSString *toDateString) {
    printf("------------------------------------\n");
    printf("Report from %s to %s\n", [fromDateString cStringUsingEncoding:NSUTF8StringEncoding], [toDateString cStringUsingEncoding:NSUTF8StringEncoding]);
    printf("------------------------------------\n");
    
    __block double totalDuration = 0.0;
    [projectsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *duration, BOOL *stop) {
        double durationDouble = [duration doubleValue];
        double hours = durationDouble / 60.0 / 60.0;
        printf("%0.2f \t %s\n", hours, [key cStringUsingEncoding:NSUTF8StringEncoding]);
        totalDuration += durationDouble;
    }];
    
    printf("------------------------------------\n");
    printf("Total duration: %0.2f\n", totalDuration / 60.0 / 60.0);
    printf("------------------------------------\n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSDictionary *argsDictionary = argumentsDictionary();
        
        NSString *title = [argsDictionary valueForKey:@"-c"];
        NSString *fromDateString = [argsDictionary valueForKey:@"-f"];
        NSString *toDateString = [argsDictionary valueForKey:@"-t"];
        NSDate *fromDate = dateFromString(fromDateString);
        NSDate *toDate = dateFromString(toDateString);

        if([[argsDictionary valueForKey:@"-h"] length] || title == nil || fromDate == nil || toDate == nil) {
            showHelp();
            exit(0);
        }
        
        BOOL useLocationInsteadOfTitle = [argsDictionary valueForKey:@"-l"] != nil;
        
        EKEventStore *store = [[EKEventStore alloc] init];
        
        [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            
            if(granted == NO) {
                printf("%s", [[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]);
                exit(1);
            }
            
            NSArray *calendars = [store calendarsForEntityType:EKEntityTypeEvent];
            
            NSArray *filteredCalendars = [calendars filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"title == %@", title]];

            if([filteredCalendars count] != 1) {
                NSLog(@"-- error: found %lu calendars with title %@", [filteredCalendars count], title);
                exit(1);
            }
            
            EKCalendar *calendar = [filteredCalendars lastObject];

            NSPredicate *predicate = [store predicateForEventsWithStartDate:fromDate
                                                                    endDate:toDate
                                                                  calendars:@[calendar]];
            
            NSArray *events = [store eventsMatchingPredicate:predicate];
            
            NSDictionary *projectsDictionary = projectsDictionaryFromEvents(events, useLocationInsteadOfTitle);

            printReport(projectsDictionary, fromDateString, toDateString);
            
            exit(0);

        }];
        
        [[NSRunLoop mainRunLoop] run];

    }
    return 0;
}
