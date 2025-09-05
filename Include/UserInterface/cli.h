#pragma once

#include <QtWidgets/QApplication>

#include "Customizer/folderCustomizer.h"

#if HAVE_BOOST_PROGRAM_OPTIONS
#include <boost/program_options.hpp>
namespace po = boost::program_options;

class CLI {
   public:
    CLI(po::variables_map vm);
};
#else
// When Boost program_options is unavailable, expose a stub so includes succeed.
class CLI;
#endif