/*
 * run_ppzksnark.cpp
 *
 *      Author: Ji xiao hui
 */

#include "CircuitReader.hpp"
#include <libsnark/gadgetlib2/integration.hpp>
#include <libsnark/gadgetlib2/adapters.hpp>
#include <libsnark/zk_proof_systems/ppzksnark/r1cs_ppzksnark/examples/run_r1cs_ppzksnark.hpp>
#include <libsnark/zk_proof_systems/ppzksnark/r1cs_ppzksnark/r1cs_ppzksnark.hpp>
#include <libsnark/zk_proof_systems/ppzksnark/r1cs_gg_ppzksnark/examples/run_r1cs_gg_ppzksnark.hpp>
#include <libsnark/zk_proof_systems/ppzksnark/r1cs_gg_ppzksnark/r1cs_gg_ppzksnark.hpp>
#include <libsnark/common/default_types/r1cs_gg_ppzksnark_pp.hpp>
#include <libff/algebra/fields/fp.hpp>

#include <sstream>
#include <type_traits>
#include <libff/common/profiling.hpp>
#include "gmp.h"
#include <algorithm>

#include<sys/time.h>


template<typename T>
void WriteMemToFile(const T& obj, const std::string path)
{
    std::stringstream ss;
    ss << obj;
    std::ofstream fh;
    fh.open(path, std::ios::binary);
    ss.rdbuf()->pubseekpos(0, std::ios_base::out);
    fh << ss.rdbuf();
    fh.flush();
    fh.close();
}

template <typename T>
void loadFromFile(std::string path, T *p)
{
    std::stringstream ss;
    std::ifstream fh(path, std::ios::binary);

    assert(fh.is_open());

    ss << fh.rdbuf();
    fh.close();
    ss.rdbuf()->pubseekpos(0, std::ios_base::in);

	//vector<char> buf(fh.seekg(0, std::ios::end).tellg());
	//fh.seekg(0, std::ios::beg).read(&buf[0], static_cast<std::streamsize>(buf.size()));
	//fh.close();

	//ss << buf.begin();
	//ss.rdbuf()->pubseekpos(0, std::ios_base::in);

   // T obj;//(std::move(buf))
    ss >> *p;
	//obj = &buf[0];

    //return obj;
}

void deserializeProvingKeyFromFile(const std::string & pk_path, r1cs_gg_ppzksnark_proving_key<libsnark::default_r1cs_gg_ppzksnark_pp> *pk)
{
	loadFromFile<r1cs_gg_ppzksnark_proving_key<libsnark::default_r1cs_gg_ppzksnark_pp>>(pk_path, pk);
    //return loadFromFile<r1cs_gg_ppzksnark_proving_key<libsnark::default_r1cs_gg_ppzksnark_pp>>(pk_path);
}

void deserializevkFromFile(const std::string & vk_path, r1cs_gg_ppzksnark_verification_key<libsnark::default_r1cs_gg_ppzksnark_pp> *vk)
{
	loadFromFile<r1cs_gg_ppzksnark_verification_key<libsnark::default_r1cs_gg_ppzksnark_pp>>(vk_path, vk);
    //return loadFromFile<r1cs_gg_ppzksnark_verification_key<libsnark::default_r1cs_gg_ppzksnark_pp>>(vk_path);
}
void serializevkToFile(const r1cs_gg_ppzksnark_verification_key<libsnark::default_r1cs_gg_ppzksnark_pp> &vk,const std::string & vk_path){
	WriteMemToFile(vk,std::string(vk_path));
}

//r1cs_constraint_system<FieldT> *cs,
void test(char* arithFilepath, char* inputsFilepath, r1cs_constraint_system<FieldT> *cs, r1cs_variable_assignment<FieldT> *full_assignment)
{
	libff::print_mem("start test");

	gadgetlib2::initPublicParamsFromDefaultPp();
	gadgetlib2::GadgetLibAdapter::resetVariableIndex();
	ProtoboardPtr pb = gadgetlib2::Protoboard::create(gadgetlib2::R1P);

	CircuitReader reader(arithFilepath, inputsFilepath, pb);
	*cs = get_constraint_system_from_gadgetlib2(*pb);
	*full_assignment = get_variable_assignment_from_gadgetlib2(*pb);

	cs->primary_input_size = reader.getNumInputs() + reader.getNumOutputs();
	cs->auxiliary_input_size = full_assignment->size() - cs->num_inputs();

	libff::print_mem("start test before");
}

r1cs_primary_input<FieldT> getPrimaryInput(char* arithFilepath, char* inputsFilepath)
{
	r1cs_primary_input<FieldT> primary_input;
	ifstream arithfs(arithFilepath, ifstream::in);
	ifstream inputfs(inputsFilepath, ifstream::in);
	string line;

	char* inputStr;

	std::vector<Wire> inputWireIds;
	unsigned int numInputs = 0;

	while (getline(arithfs, line)) {
		if (line.length() == 0) {
			continue;
		}
		inputStr = new char[line.size()];

		if ((line[0] != 'i') || (line[1] != 'n') || (line[2] != 'p') || (line[3] != 'u') || (line[4] != 't')) 
			continue;
		Wire wireId;
		sscanf(line.c_str(), "input %u", &wireId);
		numInputs++;
		inputWireIds.push_back(wireId);

		delete[] inputStr;
	}
	arithfs.close();

	
	while (getline(inputfs, line)) {
		if (line.length() == 0) {
			continue;
		}
		Wire wireId;
		inputStr = new char[line.size()];
		if (2 == sscanf(line.c_str(), "%u %s", &wireId, inputStr)) {
			for (int i = 0; i < inputWireIds.size(); ++i) {
				if (inputWireIds[i] == wireId) {
					primary_input.push_back(readFieldElementFromHex(inputStr));
					break;
				}
			}
		} else {
			printf("Error in Input\n");
			exit(-1);
		}
		delete[] inputStr;
	}
	inputfs.close();
	
	return primary_input;
}

void insertWireId(std::vector<Wire>& wireIds, const Wire & wire){
	if (wireIds.empty() ||  wire >= wireIds.back()){
		wireIds.push_back(wire);
	}else{
		wireIds.insert(lower_bound(wireIds.begin(),wireIds.end(),wire),wire);
	}
}

bool isWireExist(const std::vector<Wire>& wireIds, const Wire & wire){
	bool ret = binary_search(wireIds.begin(),wireIds.end(),wire);
	return ret;
}

int getPrimaryAndAuxiliaryInput(char* arithFilepath, char* inputsFilepath, r1cs_primary_input<FieldT>* primary_input, r1cs_auxiliary_input<FieldT>* auxiliary_input) {
	ifstream arithfs(arithFilepath, std::ios::binary);
	ifstream inputfs(inputsFilepath, ifstream::in);
	string line;

    std::stringstream ss;
    assert(arithfs.is_open());
    ss << arithfs.rdbuf();
    arithfs.close();
    ss.rdbuf()->pubseekpos(0, std::ios_base::in);

	char* inputStr;

	std::vector<Wire> inputWireIds;
	std::vector<Wire> nizkinputWireIds;

	unsigned int numInputs = 0;

	printf("start reader arithfs\n");
	while (getline(ss,line)) {//getline(arithfs, line)

		//printf("%s",line.c_str());
		if (line.size() > 4096) {
			getchar();
			getchar();			
		}

		if (line.length() == 0) {
			continue;
		}

		if ((line[0] == 'i') && (line[1] == 'n') && (line[2] == 'p') && (line[3] == 'u') && (line[4] == 't')) {
			Wire wireId;
			sscanf(line.c_str(), "input %u", &wireId);
			numInputs++;
			//insertWireId(inputWireIds,wireId);
			inputWireIds.push_back(wireId);	
		}
		else if ((line[0] == 'n') && (line[1] == 'i') && (line[2] == 'z') && (line[3] == 'k') && (line[4] == 'i') && (line[5] == 'n') && (line[6] == 'p') && (line[7] == 'u') && (line[8] == 't')) {
			Wire wireId;
			sscanf(line.c_str(), "nizkinput %u", &wireId);
			numInputs++;
			//insertWireId(nizkinputWireIds,wireId);
			nizkinputWireIds.push_back(wireId);	
		} else {
			continue;
		}
	}
//	arithfs.close();
	printf("nizkinputWireIds num = %d\n", nizkinputWireIds.size());
	printf("inputWireIds num = %d\n", inputWireIds.size());

	printf("start reader inputfs\n");
	while (getline(inputfs, line)) {
		if (line.length() == 0) {
			continue;
		}
		Wire wireId;
		inputStr = new char[line.size()];
		if (2 == sscanf(line.c_str(), "%u %s", &wireId, inputStr)) {
			// if (isWireExist(inputWireIds, wireId)){
			// 	primary_input->push_back(readFieldElementFromHex(inputStr));
			// }
			for (int i = 0; i < inputWireIds.size(); ++i) {
				if (inputWireIds[i] == wireId) {
					primary_input->push_back(readFieldElementFromHex(inputStr));
					break;
				}
			}
			// if (isWireExist(nizkinputWireIds, wireId)){
			// 	auxiliary_input->push_back(readFieldElementFromHex(inputStr));
			// }
			for (int i = 0; i < nizkinputWireIds.size(); ++i) {
				if (nizkinputWireIds[i] == wireId) {
					auxiliary_input->push_back(readFieldElementFromHex(inputStr));
					break;
				}
		 	}
		} else {
			printf("Error in Input\n");
			exit(-1);
		}
		delete[] inputStr;
	}
	inputfs.close();
	
	return 1;
}


int run_ppzksnark_test(char* arithfile, char* infile) {
	//enerator		
	libff::start_profiling();

	gadgetlib2::initPublicParamsFromDefaultPp();
	gadgetlib2::GadgetLibAdapter::resetVariableIndex();
	ProtoboardPtr pb = gadgetlib2::Protoboard::create(gadgetlib2::R1P);

	// Read the circuit, evaluate, and translate constraints
	CircuitReader reader(arithfile, infile, pb);

	struct timeval t1, t2;
	double timeuse;
    
	//setup begin
	gettimeofday(&t1,NULL); //--zy1
	r1cs_constraint_system<FieldT> cs = get_constraint_system_from_gadgetlib2(*pb);
	r1cs_variable_assignment<FieldT> full_assignment = get_variable_assignment_from_gadgetlib2(*pb);
	cs.primary_input_size = reader.getNumInputs() + reader.getNumOutputs();
	cs.auxiliary_input_size = full_assignment.size() - cs.num_inputs();

	// extract primary and auxiliary input
	r1cs_primary_input<FieldT> primary_input(full_assignment.begin(),	full_assignment.begin() + cs.num_inputs());
	r1cs_auxiliary_input<FieldT> auxiliary_input(full_assignment.begin() + cs.num_inputs(), full_assignment.end());

	if(!cs.is_satisfied(primary_input, auxiliary_input))
	{
		cout << "The constraint system is  not satisifed by the value assignment - Terminating." << endl;
		return -1;
	}

	libff::enter_block("Call to generator");
	libff::print_header("R1CS GG-ppzkSNARK Generator");
	
	//r1cs_gg_ppzksnark_keypair<libsnark::default_r1cs_gg_ppzksnark_pp> keypair = r1cs_gg_ppzksnark_generator_JXH<libsnark::default_r1cs_gg_ppzksnark_pp>(cs);
	r1cs_gg_ppzksnark_keypair<libsnark::default_r1cs_gg_ppzksnark_pp> keypair = r1cs_gg_ppzksnark_generator<libsnark::default_r1cs_gg_ppzksnark_pp>(cs);
	
	gettimeofday(&t2,NULL); //--zy2
	FILE *fpr = fopen("setuptime.txt", "a+");
	timeuse = t2.tv_sec - t1.tv_sec + (t2.tv_usec - t1.tv_usec)/1000000.0;
	fprintf(fpr, "%fs\n", timeuse);
	fclose (fpr);

	//setup end

	
	printf("\n"); 
	libff::print_indent(); 
	libff::print_mem("after generator");
	libff::leave_block("Call to generator");

	//////////////////////////////////////////////////////////////////////////////////////////////////////////
	//libff::enter_block("WriteMemToFile");
	//WriteMemToFile(keypair.pk, "mintpk.txt");
	// WriteMemToFile(keypair.vk, "mintvk.txt");
	//serializevkToFile(keypair.vk, "mintvk.txt");
	//libff::leave_block("WriteMemToFile");
	////////////////////////////////////////////////////////////////////////////////////////////////////////

//"prover
	libff::enter_block("R1CS GG-ppzkSNARK Prover");
	libff::print_header("R1CS GG-ppzkSNARK Prover");
	// gen proof start --zy
	gettimeofday(&t1,NULL); //--zy1
	r1cs_gg_ppzksnark_proof<libsnark::default_r1cs_gg_ppzksnark_pp> proof = r1cs_gg_ppzksnark_prover<libsnark::default_r1cs_gg_ppzksnark_pp>(keypair.pk, primary_input, auxiliary_input);
	gettimeofday(&t2,NULL); //--zy2
	fpr = fopen("genprooftime.txt", "a+");
	timeuse = t2.tv_sec - t1.tv_sec + (t2.tv_usec - t1.tv_usec)/1000000.0;
	fprintf(fpr, "%fs\n", timeuse);
	fclose (fpr);

	printf("\n"); libff::print_indent(); libff::print_mem("after prover");
	libff::leave_block("R1CS GG-ppzkSNARK Prover");

//"verifier")
	libff::print_header("R1CS GG-ppzkSNARK Verifier");
	gettimeofday(&t1,NULL); //--zy1
	const bool ans = r1cs_gg_ppzksnark_verifier_strong_IC<libsnark::default_r1cs_gg_ppzksnark_pp>(keypair.vk, primary_input, proof);
	gettimeofday(&t2,NULL); //--zy2
	fpr = fopen("verifyprooftime.txt", "a+");
	timeuse = t2.tv_sec - t1.tv_sec + (t2.tv_usec - t1.tv_usec)/1000000.0;
	fprintf(fpr, "%fs\n", timeuse);
	fclose (fpr);

	printf("\n"); libff::print_indent(); libff::print_mem("after verifier");
	printf("* The verification result is: %s\n", (ans ? "PASS" : "FAIL"));
	
	return 0;
}

int main(int argc, char **argv) {
	if (argc == 3)
	{
		printf("run_ppzksnark_test!\n");
		run_ppzksnark_test(argv[1], argv[2]);

		return 1;
	}

	libff::start_profiling();
	if (strcmp(argv[1], "generator") == 0)
	{
		gadgetlib2::initPublicParamsFromDefaultPp();
		gadgetlib2::GadgetLibAdapter::resetVariableIndex();
		ProtoboardPtr pb = gadgetlib2::Protoboard::create(gadgetlib2::R1P);

		// Read the circuit, evaluate, and translate constraints
		CircuitReader reader(argv[2], argv[3], pb);
		r1cs_constraint_system<FieldT> cs = get_constraint_system_from_gadgetlib2(*pb);
		r1cs_variable_assignment<FieldT> full_assignment = get_variable_assignment_from_gadgetlib2(*pb);
		cs.primary_input_size = reader.getNumInputs() + reader.getNumOutputs();
		cs.auxiliary_input_size = full_assignment.size() - cs.num_inputs();

		// extract primary and auxiliary input
		r1cs_primary_input<FieldT> primary_input(full_assignment.begin(),	full_assignment.begin() + cs.num_inputs());
		r1cs_auxiliary_input<FieldT> auxiliary_input(full_assignment.begin() + cs.num_inputs(), full_assignment.end());

		if(!cs.is_satisfied(primary_input, auxiliary_input))
		{
			cout << "The constraint system is  not satisifed by the value assignment - Terminating." << endl;
			return -1;
		}

		r1cs_variable_assignment<FieldT>().swap(full_assignment);
		r1cs_primary_input<FieldT>().swap(primary_input);
		r1cs_auxiliary_input<FieldT>().swap(auxiliary_input);

		libff::enter_block("Call to generator");
		libff::print_header("R1CS GG-ppzkSNARK Generator");
		// r1cs_gg_ppzksnark_keypair<libsnark::default_r1cs_gg_ppzksnark_pp> keypair = r1cs_gg_ppzksnark_generator_JXH<libsnark::default_r1cs_gg_ppzksnark_pp>(cs);
		r1cs_gg_ppzksnark_keypair<libsnark::default_r1cs_gg_ppzksnark_pp> keypair = r1cs_gg_ppzksnark_generator<libsnark::default_r1cs_gg_ppzksnark_pp>(cs);
		printf("\n"); 
		libff::print_indent(); 
		libff::print_mem("after generator");
		libff::leave_block("Call to generator");

		//////////////////////////////////////////////////////////////////////////////////////////////////////////
		libff::enter_block("WriteMemToFile");
		WriteMemToFile(keypair.pk, "mintpk.txt");
		// WriteMemToFile(keypair.vk, "mintvk.txt");
		serializevkToFile(keypair.vk, "mintvk.txt");
		libff::leave_block("WriteMemToFile");
		////////////////////////////////////////////////////////////////////////////////////////////////////////

		return 1;
	}
	else if (strcmp(argv[1], "prover") == 0)
	{
		// libff::print_mem("start prover");
		// gadgetlib2::initPublicParamsFromDefaultPp();
		// gadgetlib2::GadgetLibAdapter::resetVariableIndex();
		// ProtoboardPtr pb = gadgetlib2::Protoboard::create(gadgetlib2::R1P);

		// CircuitReader reader(arithFilepath, inputsFilepath, pb);
		// *cs = get_constraint_system_from_gadgetlib2(*pb);
		// *full_assignment = get_variable_assignment_from_gadgetlib2(*pb);

		// cs->primary_input_size = reader.getNumInputs() + reader.getNumOutputs();
		// cs->auxiliary_input_size = full_assignment->size() - cs->num_inputs();

		libff::print_mem("start test before");
		r1cs_constraint_system<FieldT> cs;
		r1cs_variable_assignment<FieldT> full_assignment;
		test(argv[2], argv[3], &cs, &full_assignment);//

		r1cs_primary_input<FieldT> primary_input1(full_assignment.begin(),	full_assignment.begin() + cs.num_inputs());
		r1cs_auxiliary_input<FieldT> auxiliary_input1(full_assignment.begin() + cs.num_inputs(), full_assignment.end());
		libff::print_mem("after test 1");

		// if(!cs.is_satisfied(primary_input, auxiliary_input))
		// {
		// 	cout << "The constraint system is  not satisifed by the value assignment - Terminating." << endl;
		// 	return -1;
		// }

		
		// r1cs_variable_assignment<FieldT>().swap(full_assignment);
		// libff::print_mem("after test 2");	
		

		// libff::enter_block("getPrimaryAndAuxiliaryInput");
		// r1cs_primary_input<FieldT> primary_input;
		// r1cs_auxiliary_input<FieldT> auxiliary_input;
		// getPrimaryAndAuxiliaryInput(argv[2], argv[3], &primary_input, &auxiliary_input);
		// libff::leave_block("getPrimaryAndAuxiliaryInput");
		// libff::print_mem("after getPrimaryAndAuxiliaryInput");
		// if (primary_input1 != primary_input) {
		// 	printf("!!!!!!!!!!!!!!!!1111\n");
		// }
		// if (auxiliary_input1 != auxiliary_input) {
		// 	printf("!!!!!!!!!!!!!!!!2222\n");
		// }
		// printf("%d\n",auxiliary_input1.size());
		// printf("%d\n",auxiliary_input.size());


    	r1cs_gg_ppzksnark_keypair<libsnark::default_r1cs_gg_ppzksnark_pp> keypair;

		libff::enter_block("ReadMemFromFile mintpk.txt");
    	deserializeProvingKeyFromFile("mintpk.txt", &keypair.pk);
		libff::leave_block("ReadMemFromFile mintpk.txt");
		libff::print_mem("after ReadMemFromFile mintpk.txt");

		libff::enter_block("ReadMemFromFile mintvk.txt");
		deserializevkFromFile("mintvk.txt", &keypair.vk);
		libff::leave_block("ReadMemFromFile mintvk.txt");
		libff::print_mem("after ReadMemFromFile mintvk.txt");
		
		//return 1;

		//keypair.pk.constraint_system = cs;
		
		//std::vector<r1cs_constraint<FieldT> >().swap(cs.constraints);		
		if(!keypair.pk.constraint_system.is_satisfied(primary_input1, auxiliary_input1))
		{
			cout << "The constraint system is  not satisifed by the value assignment - Terminating." << endl;
			return -1;
		}
		

		libff::enter_block("R1CS GG-ppzkSNARK Prover");
		libff::print_header("R1CS GG-ppzkSNARK Prover");
    	r1cs_gg_ppzksnark_proof<libsnark::default_r1cs_gg_ppzksnark_pp> proof = r1cs_gg_ppzksnark_prover<libsnark::default_r1cs_gg_ppzksnark_pp>(keypair.pk, primary_input1, auxiliary_input1);
    	printf("\n"); libff::print_indent(); libff::print_mem("after prover");
		libff::leave_block("R1CS GG-ppzkSNARK Prover");
		WriteMemToFile(proof, "proof");

		FILE *fpr = fopen("vkForSol.txt", "w");
		gmp_fprintf(fpr, "vk.alpha = Pairing.G1Point(uint256(%0#66Nx), uint256(%0#66Nx));\n"
		 											,keypair.vk.alpha_g1.X.as_bigint().data, 4L,keypair.vk.alpha_g1.Y.as_bigint().data, 4L);
		gmp_fprintf(fpr, "vk.beta = Pairing.G2Point([uint256(%0#66Nx), uint256(%0#66Nx)], [uint256(%0#66Nx), uint256(%0#66Nx)]);\n"
		 											,keypair.vk.beta_g2.X.c0.as_bigint().data, 4L,keypair.vk.beta_g2.X.c1.as_bigint().data, 4L
		 											,keypair.vk.beta_g2.Y.c0.as_bigint().data, 4L,keypair.vk.beta_g2.Y.c1.as_bigint().data, 4L);
		gmp_fprintf(fpr, "vk.gamma = Pairing.G2Point([uint256(%0#66Nx), uint256(%0#66Nx)], [uint256(%0#66Nx), uint256(%0#66Nx)]);\n"
													,keypair.vk.gamma_g2.X.c0.as_bigint().data, 4L,keypair.vk.gamma_g2.X.c1.as_bigint().data, 4L
													,keypair.vk.gamma_g2.Y.c0.as_bigint().data, 4L,keypair.vk.gamma_g2.Y.c1.as_bigint().data, 4L);
		gmp_fprintf(fpr, "vk.delta = Pairing.G2Point([uint256(%0#66Nx), uint256(%0#66Nx)], [uint256(%0#66Nx), uint256(%0#66Nx)]);\n"
													,keypair.vk.delta_g2.X.c0.as_bigint().data, 4L,keypair.vk.delta_g2.X.c1.as_bigint().data, 4L
													,keypair.vk.delta_g2.Y.c0.as_bigint().data, 4L,keypair.vk.delta_g2.Y.c1.as_bigint().data, 4L);
		// gmp_fprintf(fpr, "vk.gamma_abc = new Pairing.G1Point[](%d);\n"
		// 											,keypair.vk.gamma_ABC_g1.rest.size()+1);
		
		//第0个
		gmp_fprintf(fpr, "vk.gamma_abc0 = Pairing.G1Point(uint256(%0#66Nx), uint256(%0#66Nx));\n"
													,keypair.vk.gamma_ABC_g1.first.X.as_bigint().data, 4L,keypair.vk.gamma_ABC_g1.first.Y.as_bigint().data, 4L);
		gmp_fprintf(fpr, "vk.gamma_abc (%d);\n",keypair.vk.gamma_ABC_g1.rest.size());
		// //剩下的
		// for (int i = 0; i < keypair.vk.gamma_ABC_g1.rest.size(); i++)
		// {
		// 	gmp_fprintf(fpr, "vk.gamma_abc[%d] = Pairing.G1Point(uint256(%0#66Nx), uint256(%0#66Nx));\n"
		// 											,i+1
		// 											,keypair.vk.gamma_ABC_g1.rest[i].X.as_bigint().data, 4L,keypair.vk.gamma_ABC_g1.rest[i].Y.as_bigint().data, 4L);
		// }

		// gmp_fprintf(fpr, "data[0] = G1Point(uint256(%0#66Nx), uint256(%0#66Nx));\n"
		// 											,keypair.vk.gamma_ABC_g1.first.X.as_bigint().data, 4L,keypair.vk.gamma_ABC_g1.first.Y.as_bigint().data, 4L);
		for (int i = 0; i < keypair.vk.gamma_ABC_g1.rest.size(); i++)
		{
			gmp_fprintf(fpr, "data[%d] = Pairing.G1Point(uint256(%0#66Nx), uint256(%0#66Nx));\n"
													,i%200
													,keypair.vk.gamma_ABC_g1.rest[i].X.as_bigint().data, 4L,keypair.vk.gamma_ABC_g1.rest[i].Y.as_bigint().data, 4L);
		}
		fclose(fpr);

		return 1;
	}
	else if (strcmp(argv[1], "verifier") == 0)
	{
		gadgetlib2::initPublicParamsFromDefaultPp();
		gadgetlib2::GadgetLibAdapter::resetVariableIndex();
		
		r1cs_gg_ppzksnark_keypair<libsnark::default_r1cs_gg_ppzksnark_pp> keypair;
		r1cs_gg_ppzksnark_proof<libsnark::default_r1cs_gg_ppzksnark_pp> proof;

		r1cs_primary_input<FieldT> primary_input = getPrimaryInput(argv[2], argv[3]);

		libff::enter_block("ReadMemFromFile");
		deserializevkFromFile("mintvk.txt", &keypair.vk);


		libff::print_mem("ReadMemFromFile");	
		loadFromFile("proof", &proof);

	


		libff::leave_block("ReadMemFromFile");

		libff::print_header("R1CS GG-ppzkSNARK Verifier");
		const bool ans = r1cs_gg_ppzksnark_verifier_strong_IC<libsnark::default_r1cs_gg_ppzksnark_pp>(keypair.vk, primary_input, proof);
		printf("\n"); libff::print_indent(); libff::print_mem("after verifier");
		printf("* The verification result is: %s\n", (ans ? "PASS" : "FAIL"));
		
		//proof input
		FILE *fpr = fopen("proofinputForSol.txt", "w");
		gmp_fprintf(fpr, "[[%0#66Nx,%0#66Nx],",proof.g_A.X.as_bigint().data, 4L,proof.g_A.Y.as_bigint().data, 4L);
		gmp_fprintf(fpr, "[[%0#66Nx,%0#66Nx],[%0#66Nx,%0#66Nx]],"
													 ,proof.g_B.X.c0.as_bigint().data, 4L,proof.g_B.X.c1.as_bigint().data, 4L
													 ,proof.g_B.Y.c0.as_bigint().data, 4L,proof.g_B.Y.c1.as_bigint().data, 4L);
		gmp_fprintf(fpr, "[%0#66Nx,%0#66Nx],",proof.g_C.X.as_bigint().data, 4L,proof.g_C.Y.as_bigint().data, 4L);
		gmp_fprintf(fpr, "[");
		for (int i = 0; i < primary_input.size(); i++)
		{
			gmp_fprintf(fpr, "%#Nx", primary_input[i].as_bigint().data, 4L);
			if (i != (primary_input.size() - 1))
				gmp_fprintf(fpr, ",");
		}
		gmp_fprintf(fpr, "]]");
		
		// gmp_fprintf(fpr,"\n");
		// for (int i = 0; i < primary_input.size(); i++)
		// {
		// 	gmp_fprintf(fpr, "iinput[%d]=uint256(%#Nx);\n",i%200, primary_input[i].as_bigint().data, 4L);
		// }
		
		// fclose(fpr);

		// FILE *fprtest = fopen("prooftest.txt", "w");
		// gmp_fprintf(fprtest, proof.g_A.X.as_ulong().data);
		// gmp_fprintf(fprtest, proof.g_A.Y.as_ulong().data);
		// gmp_fprintf(fprtest, proof.g_B.X.c0.as_ulong().data);
		// gmp_fprintf(fprtest, proof.g_B.X.c1.as_ulong().data);
		// gmp_fprintf(fprtest, proof.g_B.Y.c0.as_ulong().data);
		// gmp_fprintf(fprtest, proof.g_B.Y.c1.as_ulong().data);
		// gmp_fprintf(fprtest, proof.g_C.X.as_ulong().data);
		// gmp_fprintf(fprtest, proof.g_C.Y.as_ulong().data);
		
		// fclose(fprtest);

		return 1;
	}
	// else if(strcmp(argv[1], "v") == 0){
	// 	//本地读vk
	// 	r1cs_gg_ppzksnark_verification_key<libsnark::default_r1cs_gg_ppzksnark_pp> vvk;
	// 	deserializevkFromFile("mintvk.txt", &vvk);
	// 	//本地读proof
	// 	return 1;
	// }
	else
	{
		return 0;
	}
}

