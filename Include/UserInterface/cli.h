#pragma once

#include <QtWidgets/QApplication>

#include <boost/program_options.hpp>

#include "Customizer/folderCustomizer.h"

namespace po = boost::program_options;

class CLI {
   public:
    CLI(po::variables_map vm);
};