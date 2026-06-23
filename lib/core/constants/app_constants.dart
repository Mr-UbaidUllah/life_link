// App-wide static reference data. Centralized so blood groups and the
// country→cities map live in exactly one place instead of being re-declared
// across feed, search and create-request screens.

/// The eight ABO/Rh blood groups, in standard display order.
const List<String> kBloodGroups = [
  "A+",
  "A-",
  "B+",
  "B-",
  "AB+",
  "AB-",
  "O+",
  "O-",
];

/// Supported countries mapped to their selectable cities. The single source of
/// truth for EVERY location picker in the app — create-request, search, profile
/// setup (personal_information) and edit-profile. Keeping them on one list is
/// what lets the notification matching compare `city` by exact value (a donor's
/// saved city must be selectable on the request side, or they'd never match).
const Map<String, List<String>> kCountryCities = {
  "Pakistan": [
    "Peshawar",
    "Lahore",
    "Karachi",
    "Islamabad",
    "Faisalabad",
    "Rawalpindi",
    "Multan",
    "Quetta",
    "Gujranwala",
    "Sialkot",
    "Hyderabad",
    "Abbottabad",
  ],
  "India": [
    "Delhi",
    "Mumbai",
    "Bangalore",
    "Kolkata",
    "Chennai",
    "Hyderabad",
    "Pune",
    "Ahmedabad",
    "Jaipur",
    "Lucknow",
  ],
  "USA": [
    "New York",
    "Los Angeles",
    "Chicago",
    "Houston",
    "Phoenix",
    "Philadelphia",
    "San Antonio",
    "San Diego",
    "Dallas",
    "San Francisco",
  ],
  "UAE": [
    "Dubai",
    "Abu Dhabi",
    "Sharjah",
    "Al Ain",
    "Ajman",
    "Ras Al Khaimah",
    "Fujairah",
  ],
  "Canada": [
    "Toronto",
    "Montreal",
    "Vancouver",
    "Calgary",
    "Ottawa",
    "Edmonton",
    "Winnipeg",
    "Quebec City",
  ],
  "United Kingdom": [
    "London",
    "Birmingham",
    "Manchester",
    "Glasgow",
    "Liverpool",
    "Leeds",
    "Bristol",
    "Edinburgh",
  ],
  "Australia": [
    "Sydney",
    "Melbourne",
    "Brisbane",
    "Perth",
    "Adelaide",
    "Canberra",
    "Gold Coast",
  ],
  "Saudi Arabia": [
    "Riyadh",
    "Jeddah",
    "Mecca",
    "Medina",
    "Dammam",
    "Khobar",
    "Taif",
  ],
  "Bangladesh": [
    "Dhaka",
    "Chittagong",
    "Khulna",
    "Rajshahi",
    "Sylhet",
    "Barisal",
  ],
  "Germany": [
    "Berlin",
    "Munich",
    "Hamburg",
    "Frankfurt",
    "Cologne",
    "Stuttgart",
  ],
};
