include_directories(${CMAKE_CURRENT_LIST_DIR})

set(HEADERS ${HEADERS}
    ${CMAKE_CURRENT_LIST_DIR}/quirc.h
    ${CMAKE_CURRENT_LIST_DIR}/quirc_internal.h)
set(SOURCES ${SOURCES}
    ${CMAKE_CURRENT_LIST_DIR}/quirc.c
    ${CMAKE_CURRENT_LIST_DIR}/decode.c
    ${CMAKE_CURRENT_LIST_DIR}/identify.c
    ${CMAKE_CURRENT_LIST_DIR}/version_db.c)