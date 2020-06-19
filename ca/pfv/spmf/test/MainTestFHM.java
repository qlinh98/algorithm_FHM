package ca.pfv.spmf.test;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URL;

// import ca.pfv.spmf.algorithms.frequentpatterns.hui_miner.AlgoFHM;
import ca.pfv.spmf.test.algo.AlgoFHM;

/**
 * Example of how to use the FHM algorithm from the source code.
 * 
 * @author Philippe Fournier-Viger, 2014
 */
public class MainTestFHM {

	public static void main(final String[] arg) throws IOException {

		// String input = fileToPath("./DB_Utility.txt");
		// String output = ".//output.txt";
		// int min_utility = 30; //

		String input = fileToPath("./BMS_utility_spmf1.txt");
		String output = ".//output_BMS.txt";
		int min_utility = 2268000; //

		// String input = fileToPath("chainstore.txt");
		// String output = ".//output_chainstore.txt";
		// int min_utility = 2600000; //

		// Applying the HUIMiner algorithm
		final AlgoFHM fhm = new AlgoFHM();
		fhm.runAlgorithm(input, output, min_utility);
		fhm.printStats();

	}

	public static String fileToPath(final String filename) throws UnsupportedEncodingException {
		final URL url = MainTestFHM.class.getResource(filename);
		return java.net.URLDecoder.decode(url.getPath(), "UTF-8");
	}
}
