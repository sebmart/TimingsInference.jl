using TimingsInference
using Base.Test

# write your own tests here
@test 1 == 1

t1 = GeoTrip(0.0f0, 1.0f0, 2.0f0, 3.0f0, DateTime(2016, 2, 9, 12, 35, 00), 60.0f0)
t2 = GeoTrip(0.0f0, 1.0f0, 2.0f0, 3.0f0, DateTime(2016, 2, 7, 13, 00, 00), 60.0f0)

@test inTimeWindow(t1, 12, 13) == true
@test inTimeWindow(t2, 12, 13) == false
@test onlyWeekdays(t1) == true
@test onlyWeekdays(t2) == false