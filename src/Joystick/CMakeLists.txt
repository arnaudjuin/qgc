
set(EXTRA_SRC)

if (ANDROID)
	list(APPEND EXTRA_SRC
		JoystickAndroid.cc
	)
endif()

qt_add_library(Joystick STATIC
	Joystick.cc
	JoystickManager.cc
	JoystickMavCommand.cc
	${EXTRA_SRC}
)

target_link_libraries(Joystick
	PUBLIC
		qgc
)

target_include_directories(Joystick PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

if(WIN32)
	target_link_libraries(Joystick PUBLIC sdl2)
endif()
