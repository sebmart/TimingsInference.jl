using TimingsInference
using Base.Test

# write your own tests here
@test 1 == 1

t1 = GeoTrip(0.0f0, 1.0f0, 2.0f0, 3.0f0, DateTime(2013, 6, 6, 12, 35, 00), 60.0f0)
t2 = GeoTrip(0.0f0, 1.0f0, 2.0f0, 3.0f0, DateTime(2013, 6, 6, 13, 00, 00), 60.0f0)

@test inTimeWindow(t1, 12, 13) == true
@test inTimeWindow(t2, 12, 13) == false